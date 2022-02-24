# EXCLUDE FROM TESTING
using VectorEngine

function kernel(addr::Int64)
   @veshow(addr)
   return
end

vefunc = VectorEngine.vefunction(kernel, Tuple{Int64})

vefunc(1234)

synchronize()
