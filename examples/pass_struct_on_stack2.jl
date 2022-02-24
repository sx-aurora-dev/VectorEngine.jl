# EXCLUDE FROM TESTING
using VectorEngine

mutable struct xm
      x::Int32
      m::Int64
end

@noinline function _pass_struct!(r::xm)
    @veprintf("r.x=%d, r.m=%ld\n", r.x, r.m)
    r.m = r.m + 1
    @veprintf("r.m=%ld\n", r.m)
end

function pass_struct!(r)
    _pass_struct!(r)
    return
end

a = xm(1, 100)

@veda pass_struct!(a)
synchronize()
@show a
