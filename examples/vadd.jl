using VectorEngine, Test

function vadd(a, b, c)
    for i = 1:prod(size(a))
        @inbounds c[i] = a[i] + b[i]
    end
    return
end

dims = (2,)
a = round.(rand(Float32, dims) * 100)
b = round.(rand(Float32, dims) * 100)
c = similar(a)

d_a = VEArray(a)
d_b = VEArray(b)
d_c = VEArray(c)

len = prod(dims)

@veda vadd(d_a, d_b, d_c)
VectorEngine.vesync()

c = Array(d_c)
@test a+b ≈ c
