# EXCLUDE FROM TESTING
using VectorEngine

function kernel(dummy::Clong, v::Clong, w::Float64)
    @veprintf("dummy = 0x%lx\n", dummy)
    @veprintf("v = %ld 0x%lx\n", v, v)
    @veprintf("w = %f  0x%lx\n", w, w)
    return nothing
end

# Compile the kernel
vefunc = VectorEngine.vefunction(kernel, Tuple{Clong, Clong, Float64})

# Launch kernel
vefunc(Clong(123), Float64(2.34))
vefunc(0, Clong(123), Float64(2.34))

VectorEngine.vesync()
