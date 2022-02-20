const allocated = Dict{Ptr{Int8},Tuple{Mem.VEBuffer,Int}}()

function allocate(bytes::Int)
    # 0-byte allocations shouldn't hit the pool
    bytes == 0 && return VE_NULL

    buf = Mem.device_alloc(bytes)

    @assert !haskey(allocated, pointer(buf))
    allocated[pointer(buf)] = buf, 1

    return buf
end

function alias(ptr)
    # 0-byte allocations shouldn't hit the pool
    ptr == VE_NULL && return

    buf, refcount = allocated[ptr]
    allocated[ptr] = buf, refcount+1

    return
end

function release(buf::Mem.VEBuffer)
    # 0-byte allocations shouldn't hit the pool
    pointer(buf) == VE_NULL && return

    buf, refcount = allocated[pointer(buf)]
    if refcount == 1
        delete!(allocated, pointer(buf))
    else
        allocated[pointer(buf)] = buf, refcount-1
        return
    end

    Mem.free(buf)

    return
end
