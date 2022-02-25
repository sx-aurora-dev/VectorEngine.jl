# EXCLUDE FROM TESTING
using VectorEngine, Test

# pass a simple but mutable struct to VE device

mutable struct xm
      x::Int32
      m::Int64
end

# VE side function that modifies the struct
function pass_struct!(r::Ref{xm})
    r[].m += 1
    return
end

a = xm(1, 100)

@synchronize @veda pass_struct!(Ref(a))
@test (a.x == 1) && (a.m == 101)

