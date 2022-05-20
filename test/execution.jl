import Adapt

using StaticArrays

dummy() = return

@testset "@veda" begin

@test_throws UndefVarError @veda undefined()
@test_throws MethodError @veda dummy(1)


@testset "low-level interface" begin
    k = vefunction(dummy)
    k()
    #k(; items=1)
end


#@testset "launch configuration" begin
#    @veda dummy()
#
#    @veda items=1 dummy()
#    @veda items=(1,1) dummy()
#    @veda items=(1,1,1) dummy()
#
#    @veda groups=1 dummy()
#    @veda groups=(1,1) dummy()
#    @veda groups=(1,1,1) dummy()
#end


@testset "launch=false" begin
    k = @veda launch=false dummy()
    k()
    #k(; items=1)
end


@testset "inference" begin
    foo() = @veda dummy()
    @inferred foo()

    # with arguments, we call kernel_convert
    kernel(a) = return
    bar(a) = @veda kernel(a)
    @inferred bar(VEArray([1]))
end


@testset "reflection" begin
    VectorEngine.code_lowered(dummy, Tuple{})
    VectorEngine.code_typed(dummy, Tuple{})
    VectorEngine.code_warntype(devnull, dummy, Tuple{})
    VectorEngine.code_llvm(devnull, dummy, Tuple{})
    VectorEngine.code_native(devnull, dummy, Tuple{})

    @device_code_lowered @veda dummy()
    @device_code_typed @veda dummy()
    @device_code_warntype io=devnull @veda dummy()
    @device_code_llvm io=devnull @veda dummy()
    @device_code_native io=devnull @veda dummy()

    mktempdir() do dir
        @device_code dir=dir @veda dummy()
    end

    @test_throws ErrorException @device_code_lowered nothing

    # make sure kernel name aliases are preserved in the generated code
    @test occursin("julia_dummy", sprint(io->(@device_code_llvm io=io optimize=false @veda dummy())))
    @test occursin("julia_dummy", sprint(io->(@device_code_llvm io=io @veda dummy())))
    @test occursin("julia_dummy", sprint(io->(@device_code_native io=io @veda dummy())))

    # make sure invalid kernels can be partially reflected upon
    let
        invalid_kernel() = throw()
        @test_throws VectorEngine.KernelError @veda invalid_kernel()
        @test_throws VectorEngine.KernelError @grab_output @device_code_warntype @veda invalid_kernel()
        out, err = @grab_output begin
            try
                @device_code_warntype @veda invalid_kernel()
            catch
            end
        end
        @test occursin("Body::Union{}", err)
    end

    let
        range_kernel() = (0.0:0.1:100.0; nothing)

        @test_throws VectorEngine.InvalidIRError @veda range_kernel()
    end

    # set name of kernel
    @test occursin("julia_mykernel", sprint(io->(@device_code_llvm io=io begin
        k = vefunction(dummy, name="mykernel")
        k()
    end)))
end


@testset "external kernels" begin
    @eval module KernelModule
        export external_dummy
        external_dummy() = return
    end
    import ...KernelModule
    @veda KernelModule.external_dummy()
    @eval begin
        using ...KernelModule
        @veda external_dummy()
    end

    @eval module WrapperModule
        using VectorEngine
        @eval dummy() = return
        wrapper() = @veda dummy()
    end
    WrapperModule.wrapper()
end


@testset "calling device function" begin
    @noinline child(i) = sink(i)
    function parent()
        child(1)
        return
    end

    VectorEngine.@veda parent()
end


@testset "varargs" begin
    function kernel(r, args...)
        r[] = args[2]
        return
    end

    r = Ref{Int}(-1)

    @veda kernel(r, 1, 2, 3)
    synchronize()
    @test r[] == 2
end

end


############################################################################################

@testset "argument passing" begin

dims = (16, 16)
len = prod(dims)

@testset "manually allocated" begin
    function kernel(input, output)
        for i = 1:length(input)
            output[i] = input[i]
        end
        return
    end

    input = round.(rand(Float32, dims) * 100)
    output = similar(input)

    input_dev = VEArray(input)
    output_dev = VEArray(output)

    @veda kernel(input_dev, output_dev)
    @test input ≈ Array(output_dev)
end


@testset "scalar through single-value array" begin
    function kernel(a, x)
        max = length(a)
        for i = 1:max
            if i == max
                x[] = a[i]
            end
        end
        return
    end

    arr = round.(rand(Float32, dims) * 100)
    val = [0f0]

    arr_dev = VEArray(arr)
    val_dev = VEArray(val)

    @veda kernel(arr_dev, val_dev)
    @test arr[dims...] ≈ Array(val_dev)[1]
end


@testset "scalar through single-value array, using device function" begin
    @noinline child(a, i) = a[i]
    function parent(a, x)
        max = length(a)
        for i = 1:max
            if i == max
                x[] = child(a, i)
            end
        end
        return
    end

    arr = round.(rand(Float32, dims) * 100)
    val = [0f0]

    arr_dev = VEArray(arr)
    val_dev = VEArray(val)

    @veda parent(arr_dev, val_dev)
    @test arr[dims...] ≈ Array(val_dev)[1]
end


@testset "tuples" begin
    # issue #7: tuples not passed by pointer

    function kernel(keeps, out)
        if keeps[1]
            out[] = 1
        else
            out[] = 2
        end
        return
    end

    keeps = (true,)
    d_out = VEArray(zeros(Int))

    @veda kernel(keeps, d_out)
    @test Array(d_out)[] == 1
end


@testset "ghost function parameters" begin
    # bug: ghost type function parameters are elided by the compiler

    len = 60
    a = rand(Float32, len)
    b = rand(Float32, len)
    c = similar(a)

    d_a = VEArray(a)
    d_b = VEArray(b)
    d_c = VEArray(c)

    @eval struct ExecGhost end

    function kernel(ghost, a, b, c)
        for i = 1:length(a)
            c[i] = a[i] + b[i]
        end
        return
    end
    @veda kernel(ExecGhost(), d_a, d_b, d_c)
    @test a+b == Array(d_c)

    # bug: ghost type function parameters confused aggregate type rewriting
    function kernel(ghost, out, aggregate)
        for i = 1:length(out)
            out[i] = aggregate[1]
        end
        return
    end
    @veda kernel(ExecGhost(), d_c, (42,))

    @test all(val->val==42, Array(d_c))
end


@testset "immutables" begin
    # issue #15: immutables not passed by pointer

    function kernel(ptr, b)
        ptr[] = imag(b)
        return
    end

    arr = VEArray(zeros(Float32))
    x = ComplexF32(2,2)

    @veda kernel(arr, x)
    @test Array(arr)[] == imag(x)
end


@testset "automatic recompilation" begin
    arr = VEArray(zeros(Int))

    function kernel(ptr)
        ptr[] = 1
        return
    end

    @veda kernel(arr)
    @test Array(arr)[] == 1

    function kernel(ptr)
        ptr[] = 2
        return
    end

    @veda kernel(arr)
    @test Array(arr)[] == 2
end


@testset "automatic recompilation (bis)" begin
    arr = VEArray(zeros(Int))

    @eval doit(ptr) = ptr[] = 1

    function kernel(ptr)
        doit(ptr)
        return
    end

    @veda kernel(arr)
    @test Array(arr)[] == 1

    @eval doit(ptr) = ptr[] = 2

    @veda kernel(arr)
    @test Array(arr)[] == 2
end


@testset "non-isbits arguments" begin
    function kernel1(T, i)
        sink(i)
        return
    end
    @veda kernel1(Int, 1)

    function kernel2(T, i)
        sink(unsafe_trunc(T,i))
        return
    end
    @veda kernel2(Int, 1.)
end


@testset "splatting" begin
    function kernel(out, a, b)
        out[] = a+b
        return
    end

    out = [0]
    out_dev = VEArray(out)

    @veda kernel(out_dev, 1, 2)
    @test Array(out_dev)[1] == 3

    all_splat = (out_dev, 3, 4)
    @veda kernel(all_splat...)
    @test Array(out_dev)[1] == 7

    partial_splat = (5, 6)
    @veda kernel(out_dev, partial_splat...)
    @test Array(out_dev)[1] == 11
end

@testset "return value by ref" begin
    x = Ref{Int}(123)

    function kernel(r)
        r[] += 10
        return
    end

    @synchronize @veda kernel(x)
    @test x[] == 133
end

@testset "pass and return mutabale struct" begin
    mutable struct xm
        x::Int32
        m::Int64
    end

    s = xm(10, 10)
    
    function kernel(s)
        s.x += 1
        s.m -= 1
        return
    end

    @synchronize @veda kernel(s)
    @test s.x == 11 && s.m == 9
end

    
@testset "object invoke" begin
    # this mimics what is generated by closure conversion
    # FAIL on VE, kills VEO context

    @eval struct KernelObject{T} <: Function
        val::T
    end

    function (self::KernelObject)(a)
        a[] = self.val
        return
    end

    function outer(a, val)
       inner = KernelObject(val)
       @veda inner(a)
    end

    a = [1.]
    a_dev = VEArray(a)

    outer(a_dev, 2.)

    @test Array(a_dev) ≈ [2.]
end

@testset "closures" begin
    # FAIL on VE, kills VEO context
    function outer(a_dev, val)
       function inner(a)
            # captures `val`
            a[] = val
            return
       end
       @veda inner(a_dev)
    end

    a = [1.]
    a_dev = VEArray(a)

    outer(a_dev, 2.)

    @test Array(a_dev) ≈ [2.]
end

@testset "conversions" begin
    @eval struct Host   end
    @eval struct Device end

    Adapt.adapt_storage(::VectorEngine.Adaptor, a::Host) = Device()

    Base.convert(::Type{Int}, ::Host)   = 1
    Base.convert(::Type{Int}, ::Device) = 2

    out = [0]

    # convert arguments
    out_dev = VEArray(out)
    let arg = Host()
        @test Array(out_dev) ≈ [0]
        function kernel(arg, out)
            out[] = convert(Int, arg)
            return
        end
        @veda kernel(arg, out_dev)
        @test Array(out_dev) ≈ [2]
    end

    # convert tuples
    out_dev = VEArray(out)
    let arg = (Host(),)
        @test Array(out_dev) ≈ [0]
        function kernel(arg, out)
            out[] = convert(Int, arg[1])
            return
        end
        @veda kernel(arg, out_dev)
        @test Array(out_dev) ≈ [2]
    end

    # convert named tuples
    out_dev = VEArray(out)
    let arg = (a=Host(),)
        @test Array(out_dev) ≈ [0]
        function kernel(arg, out)
            out[] = convert(Int, arg.a)
            return
        end
        @veda kernel(arg, out_dev)
        @test Array(out_dev) ≈ [2]
    end

    # don't convert structs
    out_dev = VEArray(out)
    @eval struct Nested
        a::Host
    end
    let arg = Nested(Host())
        @test Array(out_dev) ≈ [0]
        function kernel(arg, out)
            out[] = convert(Int, arg.a)
            return
        end
        @veda kernel(arg, out_dev)
        @test Array(out_dev) ≈ [1]
    end
end

@testset "argument count" begin
    val = [0]
    val_dev = VEArray(val)
    for i in (1, 10, 20, 34)
        variables = ('a':'z'..., 'A':'Z'...)
        params = [Symbol(variables[j]) for j in 1:i]
        # generate a kernel
        body = quote
            function kernel(arr, $(params...))
                arr[] = $(Expr(:call, :+, params...))
                return
            end
        end
        eval(body)
        args = [j for j in 1:i]
        call = Expr(:call, :kernel, val_dev, args...)
        vedacall = :(@veda $call)
        eval(vedacall)
        @test Array(val_dev)[1] == sum(args)
    end
end

@testset "keyword arguments" begin
    @eval inner_kwargf(foobar;foo=1, bar=2) = nothing

    @veda (()->inner_kwargf(42;foo=1,bar=2))()

    @veda (()->inner_kwargf(42))()

    @veda (()->inner_kwargf(42;foo=1))()

    @veda (()->inner_kwargf(42;bar=2))()

    @veda (()->inner_kwargf(42;bar=2,foo=1))()
end

@testset "captured values" begin
    function f(capture::T) where {T}
        function kernel(ptr)
            ptr[] = capture
            return
        end

        arr = VEArray(zeros(T))
        @veda kernel(arr)

        return Array(arr)[1]
    end

    using Test
    @test f(1) == 1
    @test f(2) == 2
end

end

############################################################################################

#?#@testset "#55: invalid integers created by alloc_opt" begin
#?#    function f(a)
#?#        x = SVector(0f0, 0f0)
#?#        v = MVector{3, Float32}(undef)
#?#        for (i,_) in enumerate(x)
#?#            v[i] = 1.0f0
#?#        end
#?#        a[1] = v[1]
#?#        return nothing
#?#    end
#?#    @veda f(VEArray(zeros(1)))
#?#end


############################################################################################
