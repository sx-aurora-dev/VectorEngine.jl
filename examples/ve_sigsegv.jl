# EXCLUDE FROM TESTING
using VectorEngine

function do_sigsegv(addr::Int64)
   @veshow(unsafe_load(convert(Ptr{Int64}, addr)))
   return
end

vesig = VectorEngine.vefunction(do_sigsegv, Tuple{Int64})

vesig(0)

VectorEngine.vesync()
