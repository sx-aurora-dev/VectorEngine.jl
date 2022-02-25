using VectorEngine, Test

mutable struct xm
      x::Int32
      m::Int64
end

function pass_struct!(r::xm)
    r.x -= 2
    r.m += 1
    return
end

a = xm(1, 100)

@veda pass_struct!(a)
synchronize()
@test a.x == -1 && a.m == 101
