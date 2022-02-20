# Raw memory management

export Mem, available_memory, total_memory

module Mem

using ..VectorEngine
import .VectorEngine: VEDA
import .VEDA: API

using Printf


#
# buffers
#

# a chunk of memory allocated using the VEDA APIs. this memory can reside on the host, on
# the VE, or can represent specially-formatted memory (like texture arrays). depending on
# all that, the buffer may be `convert`ed to a Ptr, VEPtr, or VEArrayPtr.

abstract type AbstractBuffer end

Base.convert(T::Type{<:Union{Ptr,VEPtr,VEArrayPtr}}, buf::AbstractBuffer) =
    throw(ArgumentError("Illegal conversion of a $(typeof(buf)) to a $T"))

# ccall integration
#
# taking the pointer of a buffer means returning the underlying pointer,
# and not the pointer of the buffer object itself.
Base.unsafe_convert(T::Type{<:Union{Ptr,VEPtr,VEArrayPtr}}, buf::AbstractBuffer) = convert(T, buf)


## host side device buffer

"""
    Mem.VEBuffer

Host residing structure representing a buffer of device memory.
"""
mutable struct VEBuffer <: AbstractBuffer
    ptr::API.VEDAdeviceptr
    bytesize::Int
end

Base.pointer(buf::VEBuffer) = buf.ptr
Base.sizeof(buf::VEBuffer) = buf.bytesize

Base.show(io::IO, buf::VEBuffer) =
    @printf(io, "VEBuffer(%s at %p)", Base.format_bytes(sizeof(buf)), Int(pointer(buf)))

Base.convert(::Type{API.VEDAdeviceptr}, buf::VEBuffer) where {T} = buf.ptr


"""
    Mem.device_alloc(VEBuffer, bytesize::Integer)

Allocate `bytesize` bytes of memory on the device. This memory is only accessible on the
VE, and requires explicit calls to `unsafe_copyto!`, which wraps `vedaMemcpy`,
for access on the CPU.
"""
function device_alloc(bytesize::Integer)
    bytesize == 0 && return VEBuffer(VE_NULL, 0)

    ptr_ref = Ref{API.VEDAdeviceptr}()
    API.vedaMemAlloc(ptr_ref, bytesize)

    return VEBuffer(ptr_ref[], bytesize)
end


function free(buf::VEBuffer)
    if pointer(buf) != VE_NULL
        API.vedaMemFree(buf.ptr)
    end
end


############################################################



## host buffer

"""
    Mem.HostBuffer
    Mem.Host

A buffer of pinned memory on the CPU, unaccessible to the VE.
"""
mutable struct HostBuffer <: AbstractBuffer
    ptr::Ptr{Cvoid}
    bytesize::Int
end

Base.pointer(buf::HostBuffer) = buf.ptr
Base.sizeof(buf::HostBuffer) = buf.bytesize

Base.show(io::IO, buf::HostBuffer) =
    @printf(io, "HostBuffer(%s at %p)", Base.format_bytes(sizeof(buf)), Int(pointer(buf)))

Base.convert(::Type{Ptr{T}}, buf::HostBuffer) where {T} =
    convert(Ptr{T}, pointer(buf))

function Base.convert(::Type{VEPtr{T}}, buf::HostBuffer) where {T}
    throw(ArgumentError("cannot take the VE address of a CPU buffer"))
end


"""
    Mem.alloc(HostBuffer, bytesize::Integer)

Allocate `bytesize` bytes of page-locked memory on the host. This memory is accessible from
the CPU, and makes it possible to perform faster memory copies to the VE.
"""
function alloc(::Type{HostBuffer}, bytesize::Integer)
    bytesize == 0 && return HostBuffer(C_NULL, 0)

    ptr_ref = Ref{Ptr{Cvoid}}()
    API.vedaMemAllocHost(ptr_ref, bytesize)

    return HostBuffer(ptr_ref[], bytesize)
end

function free(buf::HostBuffer)
    if pointer(buf) != VE_NULL
        API.vedaMemFreeHost(buf.ptr)
    end
end


## array buffer

mutable struct ArrayBuffer{T,N} <: AbstractBuffer
    ptr::VEArrayPtr{T}
    dims::Dims{N}
end

Base.pointer(buf::ArrayBuffer) = buf.ptr
Base.sizeof(buf::ArrayBuffer) = error("Opaque array buffers do not have a definite size")
Base.size(buf::ArrayBuffer) = buf.dims
Base.length(buf::ArrayBuffer) = prod(buf.dims)
Base.ndims(buf::ArrayBuffer{<:Any,N}) where {N} = N

Base.show(io::IO, buf::ArrayBuffer{T,1}) where {T} =
    @printf(io, "%g-element ArrayBuffer{%s,%g}(%p)", length(buf), string(T), 1, Int(pointer(buf)))
Base.show(io::IO, buf::ArrayBuffer{T}) where {T} =
    @printf(io, "%s ArrayBuffer{%s,%g}(%p)", Base.inds2string(size(buf)), string(T), ndims(buf), Int(pointer(buf)))

# array buffers are typed, so refuse arbitrary conversions
Base.convert(::Type{VEArrayPtr{T}}, buf::ArrayBuffer{T}) where {T} =
    convert(VEArrayPtr{T}, pointer(buf))
# ... except for VEArrayPtr{Nothing}, which is used to call untyped API functions
Base.convert(::Type{VEArrayPtr{Nothing}}, buf::ArrayBuffer)  =
    convert(VEArrayPtr{Nothing}, pointer(buf))

function alloc(::Type{<:ArrayBuffer{T}}, dims::Dims{N}) where {T,N}
    format = convert(CUarray_format, eltype(T))

    if N == 2
        width, height = dims
        depth = 0
        @assert 1 <= width "VEDA 2D array (texture) width must be >= 1"
        # @assert witdh <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_WIDTH
        @assert 1 <= height "VEDA 2D array (texture) height must be >= 1"
        # @assert height <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_HEIGHT
    elseif N == 3
        width, height, depth = dims
        @assert 1 <= width "VEDA 3D array (texture) width must be >= 1"
        # @assert witdh <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_WIDTH
        @assert 1 <= height "VEDA 3D array (texture) height must be >= 1"
        # @assert height <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_HEIGHT
        @assert 1 <= depth "VEDA 3D array (texture) depth must be >= 1"
        # @assert depth <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_DEPTH
    elseif N == 1
        width = dims[1]
        height = depth = 0
        @assert 1 <= width "VEDA 1D array (texture) width must be >= 1"
        # @assert witdh <= CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_WIDTH
    else
        "VEDA arrays (texture memory) can only have 1, 2 or 3 dimensions"
    end

    allocateArray_ref = Ref(CUDA.CUDA_ARRAY3D_DESCRIPTOR(
        width, # Width::Csize_t
        height, # Height::Csize_t
        depth, # Depth::Csize_t
        format, # Format::CUarray_format
        UInt32(CUDA.nchans(T)), # NumChannels::UInt32
        0))

    handle_ref = Ref{CUarray}()
    API.vedaArray3DCreate(handle_ref, allocateArray_ref)
    ptr = reinterpret(VEArrayPtr{T}, handle_ref[])

    return ArrayBuffer{T,N}(ptr, dims)
end

function free(buf::ArrayBuffer)
    API.vedaArrayDestroy(buf.ptr)
end


## convenience aliases

#const Device  = DeviceBuffer
#const Host    = HostBuffer
#const Array   = ArrayBuffer


#
# pointers
#

## initialization

"""
    Mem.set!(buf::VEPtr, value::Union{Int8,UInt8,Int16,UInt16,Int32,UInt32,
                                      Int64,UInt64,Float32,Float64}, len::Integer;
             async::Bool=false, stream::VEStream)

Initialize device memory by copying `val` for `len` times. Executed asynchronously if
`async` is true, in which case a valid `stream` is required.
"""
set!

for T in [Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64, Float32, Float64]
    bits = 8*sizeof(T)
    fn_sync = Symbol("vedaMemsetD$(bits)")
    fn_async = Symbol("vedaMemsetD$(bits)Async")
    U = Symbol("UInt$(bits)")
    @eval function set!(ptr::VEPtr{$T}, value::$T, len::Integer;
                        async::Bool=false, stream::Union{Nothing,VEStream}=nothing)
        val = typeof(value) == $U ? value : reinterpret($U, value)
        if async
          stream===nothing &&
              throw(ArgumentError("Asynchronous memory operations require a stream."))
            $(getproperty(VectorEngine.VEDA.API, fn_async))(ptr, val, len, stream)
        else
          stream===nothing ||
              throw(ArgumentError("Synchronous memory operations cannot be issued on a stream."))
            $(getproperty(VectorEngine.VEDA.API, fn_sync))(ptr, val, len)
        end
    end
end


## copy operations

for (f, fa, srcPtrTy, dstPtrTy) in (("vedaMemcpyDtoH", "vedaMemcpyDtoHAsync", VEPtr, Ptr),
                                    ("vedaMemcpyHtoD", "vedaMemcpyHtoDAsync", Ptr,   VEPtr),
                                    ("vedaMemcpyDtoD", "vedaMemcpyDtoDAsync", VEPtr, VEPtr),
                                   )
    @eval function Base.unsafe_copyto!(dst::$dstPtrTy{T}, src::$srcPtrTy{T}, N::Integer;
                                       stream::Union{Nothing,VEStream}=nothing,
                                       async::Bool=false) where T
        if async
            stream===nothing &&
                throw(ArgumentError("Asynchronous memory operations require a stream."))
            $(getproperty(VectorEngine.VEDA.API, Symbol(fa)))(dst, src, N*sizeof(T), stream)
        else
            stream===nothing ||
                throw(ArgumentError("Synchronous memory operations cannot be issued on a stream."))
            $(getproperty(VectorEngine.VEDA.API, Symbol(f)))(dst, src, N*sizeof(T))
        end
        return dst
    end
end

function Base.unsafe_copyto!(dst::VEArrayPtr{T}, src::Ptr{T}, N::Integer;
                             stream::Union{Nothing,VEStream}=nothing,
                             async::Bool=false) where T
    if async
        stream===nothing &&
            throw(ArgumentError("Asynchronous memory operations require a stream."))
        API.vedaMemcpyHtoDAsync(dst, src, N*sizeof(T), stream)
    else
        stream===nothing ||
            throw(ArgumentError("Synchronous memory operations cannot be issued on a stream."))
        API.vedaMemcpyHtoD(dst+doffs-1, src, N*sizeof(T))
    end
end

function Base.unsafe_copyto!(dst::Ptr{T}, src::VEArrayPtr{T}, soffs::Integer, N::Integer;
                             stream::Union{Nothing,VEStream}=nothing,
                             async::Bool=false) where T
    if async
        stream===nothing &&
            throw(ArgumentError("Asynchronous memory operations require a stream."))
        API.vedaMemcpyAtoHAsync(dst, src, soffs, N*sizeof(T), stream)
    else
        stream===nothing ||
            throw(ArgumentError("Synchronous memory operations cannot be issued on a stream."))
        API.vedaMemcpyAtoH(dst, src, soffs, N*sizeof(T))
    end
end

Base.unsafe_copyto!(dst::VEArrayPtr{T}, doffs::Integer, src::VEPtr{T}, N::Integer) where {T} =
    API.vedaMemcpyDtoA(dst, doffs, src, N*sizeof(T))

Base.unsafe_copyto!(dst::VEPtr{T}, src::VEArrayPtr{T}, soffs::Integer, N::Integer) where {T} =
    API.vedaMemcpyAtoD(dst, src, soffs, N*sizeof(T))

Base.unsafe_copyto!(dst::VEArrayPtr, src, N::Integer; kwargs...) =
    Base.unsafe_copyto!(dst, 0, src, N; kwargs...)

Base.unsafe_copyto!(dst, src::VEArrayPtr, N::Integer; kwargs...) =
    Base.unsafe_copyto!(dst, src, 0, N; kwargs...)

## memory info

function info()
    free_ref = Ref{Csize_t}()
    total_ref = Ref{Csize_t}()
    API.vedaMemGetInfo(free_ref, total_ref)
    return convert(Int, free_ref[]), convert(Int, total_ref[])
end

end # module Mem

"""
    available_memory()

Returns the available_memory amount of memory (in bytes), available for allocation by the CUDA context.
"""
available_memory() = Mem.info()[1]

"""
    total_memory()

Returns the total amount of memory (in bytes), available for allocation by the CUDA context.
"""
total_memory() = Mem.info()[2]


# memory operations

function unsafe_fill!(ptr::Union{Ptr{T},VEPtr{T}},
                      pattern::Union{Ptr{T},VEPtr{T}}, N::Integer) where T
    bytes = N*sizeof(T)
    bytes==0 && return
    Mem.set!(ptr, pattern, N)
end


