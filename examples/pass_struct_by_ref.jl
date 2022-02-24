using VectorEngine, Test

# pass a simple but mutable struct to VE device

mutable struct xm
      x::Int32
      m::Int64
end

# VE side function that modifies the struct
function pass_struct!(p::Ptr{xm})
    r::xm = unsafe_load(p)
    @veprintf("r.x=%d, r.m=%ld\n", r.x, r.m)
    r.m = r.m + 1
    @veprintf("r.m=%ld\n", r.m)
    unsafe_store!(p, r)
    return
end

vepsm = VectorEngine.vefunction(pass_struct!, Tuple{Ptr{xm}})

a = xm(1, 100)

#@veda pass_struct!(Ref(a))
vepsm(Ref(a))
synchronize()
@test (a.x == 1) && (a.m == 101)
@show a


