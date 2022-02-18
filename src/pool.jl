const allocated = Dict{VEPtr,Tuple{Mem.DeviceBuffer,Int}}()

function allocate(bytes::Int)
    # 0-byte allocations shouldn't hit the pool
    bytes == 0 && return VE_NULL

    buf = Mem.device_alloc(bytes)

    ptr = convert(VEPtr{Nothing}, buf)
    @assert !haskey(allocated, ptr)
    allocated[ptr] = buf, 1

    return buf
end

function alias(ptr)
    # 0-byte allocations shouldn't hit the pool
    ptr == VE_NULL && return

    buf, refcount = allocated[ptr]
    allocated[ptr] = buf, refcount+1

    return
end

function release(ptr)
    # 0-byte allocations shouldn't hit the pool
    ptr == VE_NULL && return

    buf, refcount = allocated[ptr]
    if refcount == 1
        delete!(allocated, ptr)
    else
        allocated[ptr] = buf, refcount-1
        return
    end

    Mem.free(buf)

    return
end
