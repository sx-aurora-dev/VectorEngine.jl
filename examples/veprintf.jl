using VectorEngine

function kernel(v::Int64)
    @veprintf("v = %ld\n", v)
    return nothing
end

# Compile the kernel
vefunc = VectorEngine.vefunction(kernel, Tuple{Int64})

# Launch kernel
vefunc(123)

VectorEngine.vesync()
