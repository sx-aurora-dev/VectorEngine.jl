using VectorEngine

# pass a simple but mutable struct to VE device

mutable struct xm
      x::Int32
      m::Int64
end

# VE side function that modifies the struct
function pass_struct!(r::xm)
    r.m = r.m + 1
    return
end

vepsm = VectorEngine.vefunction(pass_struct!, Tuple{xm})

a = xm(1, 100)

vepsm(a)
VectorEngine.vesync()

a
