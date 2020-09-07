using VectorEngine

function kernel()
    return nothing
end

# Compile the kernel
vefunc = VectorEngine.vefunction(kernel)

# Launch kernel
vefunc()

VectorEngine.VEDA.API.vedaCtxSynchronize()
