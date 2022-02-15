using VectorEngine

function kernel()
    @veprintf("Hello world from VE!\n")
    return nothing
end

# Compile the kernel
vefunc = VectorEngine.vefunction(kernel)

# Launch kernel
vefunc()

VectorEngine.vesync()
