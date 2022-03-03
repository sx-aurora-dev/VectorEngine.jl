using VectorEngine, Test

@testset "vadd float64" begin
    
    dims = (1123,)             # intentionally an odd number
    a = round.(rand(Float64, dims) * 100)
    b = round.(rand(Float64, dims) * 100)
    c = similar(a)

    d_a = VEArray(a)
    d_b = VEArray(b)
    d_c = VEArray(c)

    function add_float64(a, b, c)
        @vectorize for i = 1:prod(size(a))
            @inbounds c[i] = a[i] + b[i]
        end
        return
    end

    @synchronize @veda add_float64(d_a, d_b, d_c)
    c = Array(d_c)
    @test a+b ≈ c

    out = sprint(io->(@device_code_native io=io @veda add_float64(d_a, d_b, d_c)))

    # do we see vld, vst, vfadd in the output?
    @test occursin("vld", out)
    @test occursin("vst", out)
    @test occursin("vfadd", out)

end    

@testset "vadd float32" begin
    
    dims = (1123,)             # intentionally an odd number
    a = round.(rand(Float32, dims) * 100)
    b = round.(rand(Float32, dims) * 100)
    c = similar(a)

    d_a = VEArray(a)
    d_b = VEArray(b)
    d_c = VEArray(c)

    function add_float32(a, b, c)
        @vectorize length=512 for i = 1:prod(size(a))
            @inbounds c[i] = a[i] + b[i]
        end
        return
    end

    @synchronize @veda add_float32(d_a, d_b, d_c)
    c = Array(d_c)
    @test a+b ≈ c

    out = sprint(io->(@device_code_native io=io @veda add_float32(d_a, d_b, d_c)))

    # do we see vld, vst, pvfadd in the output?
    @test occursin("vld", out)
    @test occursin("vst", out)
    @test occursin("pvfadd", out)
    @test occursin("512", out)

end    
