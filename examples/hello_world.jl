using VectorEngine

@inline function puts(str)
    ccall("extern puts", llvmcall, Int32, (Ptr{UInt8},), str)
end

function kernel()
    puts(@static_string("Hello world from VE!\n"))
    return nothing
end

# Compile the kernel
vefunc = VectorEngine.vefunction(kernel)

# Launch kernel
vefunc()

VectorEngine.vesync()
