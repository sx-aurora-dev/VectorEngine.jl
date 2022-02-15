using VectorEngine

function kernel()
    p = malloc(UInt64(256))
    hostname = convert(Ptr{UInt8}, p)
    err = ccall("extern gethostname", llvmcall, Int32,
                       (Ptr{UInt8}, Csize_t),
                       hostname, 256)
    ccall("extern puts", llvmcall, Int32, (Ptr{UInt8},), hostname)
    free(Ptr{Cvoid}(hostname))
    return nothing
end

# Compile the kernel
vefunc = VectorEngine.vefunction(kernel)

# Launch kernel
vefunc()

VectorEngine.vesync()
