# constructors
voidptr_a = VEPtr{Cvoid}(Int(0xDEADBEEF))
@test reinterpret(Ptr{Cvoid}, voidptr_a) == Ptr{Cvoid}(Int(0xDEADBEEF))

# getters
@test eltype(voidptr_a) == Cvoid

# comparisons
voidptr_b = VEPtr{Cvoid}(Int(0xCAFEBABE))
@test voidptr_a != voidptr_b


@testset "conversions" begin

# between host and device pointers
@test_throws ArgumentError convert(Ptr{Cvoid}, voidptr_a)

# between VE pointers
intptr_a = VEPtr{Int}(Int(0xDEADBEEF))
@test convert(typeof(intptr_a), voidptr_a) == intptr_a

# convert back and forth from UInt
intptr_b = VEPtr{Int}(Int(0xDEADBEEF))
@test convert(UInt, intptr_b) == 0xDEADBEEF
@test convert(VEPtr{Int}, Int(0xDEADBEEF)) == intptr_b
@test Int(intptr_b) == Int(0xDEADBEEF)

# pointer arithmetic
intptr_c = VEPtr{Int}(Int(0xDEADBEEF))
intptr_d = 2 + intptr_c
@test isless(intptr_c, intptr_d)
@test intptr_d - intptr_c == 2
@test intptr_d - 2 == intptr_c

end


@testset "VE or CPU integration" begin

a = [1]
ccall(:clock, Nothing, (Ptr{Int},), a)
@test_throws Exception ccall(:clock, Nothing, (VEPtr{Int},), a)
ccall(:clock, Nothing, (PtrOrVEPtr{Int},), a)

end


@testset "reference values" begin
    # Ref

    @test typeof(Base.cconvert(Ref{Int}, 1)) == typeof(Ref(1))
    @test Base.unsafe_convert(Ref{Int}, Base.cconvert(Ref{Int}, 1)) isa Ptr{Int}

    ptr = reinterpret(Ptr{Int}, C_NULL)
    @test Base.cconvert(Ref{Int}, ptr) == ptr
    @test Base.unsafe_convert(Ref{Int}, Base.cconvert(Ref{Int}, ptr)) == ptr

    arr = [1]
    @test Base.cconvert(Ref{Int}, arr) isa Base.RefArray{Int, typeof(arr)}
    @test Base.unsafe_convert(Ref{Int}, Base.cconvert(Ref{Int}, arr)) == pointer(arr)


    # VERef

    @test typeof(Base.cconvert(VERef{Int}, 1)) == typeof(VERef(1))
    @test Base.unsafe_convert(VERef{Int}, Base.cconvert(VERef{Int}, 1)) isa VERef{Int}

    veptr = reinterpret(VEPtr{Int}, C_NULL)
    @test Base.cconvert(VERef{Int}, veptr) == veptr
    @test Base.unsafe_convert(VERef{Int}, Base.cconvert(VERef{Int}, veptr)) == Base.bitcast(VERef{Int}, veptr)

    # TODO
    #vearr = oneAPI.oneArray([1])
    #@test Base.cconvert(VERef{Int}, vearr) isa oneL0.VERefArray{Int, typeof(vearr)}
    #@test Base.unsafe_convert(VERef{Int}, Base.cconvert(VERef{Int}, vearr)) == Base.bitcast(VERef{Int}, pointer(vearr))


    # RefOrVERef

    @test typeof(Base.cconvert(RefOrVERef{Int}, 1)) == typeof(Ref(1))
    @test Base.unsafe_convert(RefOrVERef{Int}, Base.cconvert(RefOrVERef{Int}, 1)) isa RefOrVERef{Int}

    @test Base.cconvert(RefOrVERef{Int}, ptr) == ptr
    @test Base.unsafe_convert(RefOrVERef{Int}, Base.cconvert(RefOrVERef{Int}, ptr)) == Base.bitcast(RefOrVERef{Int}, ptr)

    @test Base.cconvert(RefOrVERef{Int}, veptr) == veptr
    @test Base.unsafe_convert(RefOrVERef{Int}, Base.cconvert(RefOrVERef{Int}, veptr)) == Base.bitcast(RefOrVERef{Int}, veptr)

    @test Base.cconvert(RefOrVERef{Int}, arr) isa Base.RefArray{Int, typeof(arr)}
    @test Base.unsafe_convert(RefOrVERef{Int}, Base.cconvert(RefOrVERef{Int}, arr)) == Base.bitcast(RefOrVERef{Int}, pointer(arr))

    # TODO
    #@test Base.cconvert(RefOrVERef{Int}, vearr) isa oneL0.VERefArray{Int, typeof(vearr)}
    #@test Base.unsafe_convert(RefOrVERef{Int}, Base.cconvert(RefOrVERef{Int}, vearr)) == Base.bitcast(RefOrVERef{Int}, pointer(vearr))
end
