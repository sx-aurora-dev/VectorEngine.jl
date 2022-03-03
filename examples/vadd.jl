using VectorEngine, Test

function vadd(a, b, c)
    @vectorize for i = 1:(prod(size(a)))
        @inbounds c[i] = a[i] + b[i]
    end
    return
end

dims = (512,)
a = round.(rand(Float64, dims) * 100)
b = round.(rand(Float64, dims) * 100)
c = similar(a)

d_a = VEArray(a)
d_b = VEArray(b)
d_c = VEArray(c)

@synchronize @veda vadd(d_a, d_b, d_c)

c = Array(d_c)
@test a+b ≈ c
