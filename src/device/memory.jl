using ..VectorEngine
import .VectorEngine: VEDA
import .VEDA: API
import .Mem: VEBuffer

export malloc, free, VEDeviceBuffer

@inline function malloc(sz::Csize_t)::Ptr{Cvoid}
    ccall("extern malloc", llvmcall, Ptr{Cvoid}, (Csize_t,), sz)
end

@inline function free(ptr::Ptr{Cvoid})
    ccall("extern free", llvmcall, Cvoid, (Ptr{Cvoid},), ptr)
end


## device side device buffer

"""
    Mem.VEDeviceBuffer

Host residing structure representing a buffer of device memory.
"""
mutable struct VEDeviceBuffer
    ptr::VEPtr{Cvoid}
    bytesize::Int
    VEDeviceBuffer(p::VEPtr{Cvoid}, bsize::Int) = new(p, bsize)
end

function VEDeviceBuffer(vb::VEBuffer)
    vdb = VEDeviceBuffer(VE_NULL, vb.bytesize)
    API.vedaMemPtr(pointer(vdb), vb.ptr)
    #ccall("extern vedaMemPtr", llvmcall, Int64, (Ptr{Ptr{Cvoid}}, Ptr{Cvoid}), pointer_from_objref(vdb), vb.ptr)
    @veprintf("real pointer 0x%p\n", UInt64(vdb.ptr))
    vdb
end

Base.pointer(buf::VEDeviceBuffer) = pointer_from_objref(buf)
Base.sizeof(buf::VEDeviceBuffer) = buf.bytesize

#Base.show(io::IO, buf::VEBuffer) =
#    @veprintf(io, "VEDeviceBuffer(%s at %p)", Base.format_bytes(sizeof(buf)), Int(buf.ptr))

Base.convert(::Type{VEPtr{T}}, buf::VEDeviceBuffer) where {T} = buf.ptr

Base.unsafe_convert(::Type{VEDeviceBuffer}, vb::VEBuffer) = VEDeviceBuffer(vb)

