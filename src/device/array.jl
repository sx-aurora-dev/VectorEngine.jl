# Contiguous on-device arrays

export VEDeviceArray, VEDeviceVector, VEDeviceMatrix


## construction

# NOTE: we can't support the typical `tuple or series of integer` style construction,
#       because we're currently requiring a trailing pointer argument.

struct VEDeviceArray{T,N,A} <: AbstractArray{T,N}
    shape::Dims{N}
    ptr::LLVMPtr{T,A}

    # inner constructors, fully parameterized, exact types (ie. Int not <:Integer)
    VEDeviceArray{T,N,A}(shape::Dims{N}, ptr::LLVMPtr{T,A}) where {T,A,N} = new(shape,ptr)
end

const VEDeviceVector = VEDeviceArray{T,1,A} where {T,A}
const VEDeviceMatrix = VEDeviceArray{T,2,A} where {T,A}

# outer constructors, non-parameterized
VEDeviceArray(dims::NTuple{N,<:Integer}, p::LLVMPtr{T,A})    where {T,A,N} = VEDeviceArray{T,N,A}(dims, p)
VEDeviceArray(len::Integer,              p::LLVMPtr{T,A})    where {T,A}   = VEDeviceVector{T,A}((len,), p)

# outer constructors, partially parameterized
VEDeviceArray{T}(dims::NTuple{N,<:Integer},   p::LLVMPtr{T,A}) where {T,A,N} = VEDeviceArray{T,N,A}(dims, p)
VEDeviceArray{T}(len::Integer,                p::LLVMPtr{T,A}) where {T,A}   = VEDeviceVector{T,A}((len,), p)
VEDeviceArray{T,N}(dims::NTuple{N,<:Integer}, p::LLVMPtr{T,A}) where {T,A,N} = VEDeviceArray{T,N,A}(dims, p)
VEDeviceVector{T}(len::Integer,               p::LLVMPtr{T,A}) where {T,A}   = VEDeviceVector{T,A}((len,), p)

# outer constructors, fully parameterized
VEDeviceArray{T,N,A}(dims::NTuple{N,<:Integer}, p::LLVMPtr{T,A}) where {T,A,N} = VEDeviceArray{T,N,A}(Int.(dims), p)
VEDeviceVector{T,A}(len::Integer,               p::LLVMPtr{T,A}) where {T,A}   = VEDeviceVector{T,A}((Int(len),), p)


## getters

Base.pointer(a::VEDeviceArray) = a.ptr
Base.pointer(a::VEDeviceArray, i::Integer) =
    pointer(a) + (i - 1) * Base.elsize(a)

Base.elsize(::Type{<:VEDeviceArray{T}}) where {T} = sizeof(T)
Base.size(g::VEDeviceArray) = g.shape
Base.length(g::VEDeviceArray) = prod(g.shape)


## conversions

Base.unsafe_convert(::Type{LLVMPtr{T,A}}, a::VEDeviceArray{T,N,A}) where {T,A,N} = pointer(a)


## indexing intrinsics

# NOTE: these intrinsics are now implemented using plain and simple pointer operations;
#       when adding support for isbits union arrays we will need to implement that here.

# TODO: how are allocations aligned by the level zero API? keep track of this
#       because it enables optimizations like Load Store Vectorization
#       (cfr. shared memory and its wider-than-datatype alignment)

@inline function arrayref(A::VEDeviceArray{T}, index::Int) where {T}
    @boundscheck checkbounds(A, index)
    align = Base.datatype_alignment(T)
    unsafe_load(pointer(A), index, Val(align))
end

@inline function arrayset(A::VEDeviceArray{T}, x::T, index::Int) where {T}
    @boundscheck checkbounds(A, index)
    align = Base.datatype_alignment(T)
    unsafe_store!(pointer(A), x, index, Val(align))
    return A
end

@inline function const_arrayref(A::VEDeviceArray{T}, index::Int) where {T}
    @boundscheck checkbounds(A, index)
    align = Base.datatype_alignment(T)
    unsafe_cached_load(pointer(A), index, Val(align))
end


## indexing

Base.@propagate_inbounds Base.getindex(A::VEDeviceArray{T}, i1::Int) where {T} =
    arrayref(A, i1)
Base.@propagate_inbounds Base.setindex!(A::VEDeviceArray{T}, x, i1::Int) where {T} =
    arrayset(A, convert(T,x)::T, i1)

Base.IndexStyle(::Type{<:VEDeviceArray}) = Base.IndexLinear()


## const indexing

"""
    Const(A::VEDeviceArray)

Mark a VEDeviceArray as constant/read-only. The invariant guaranteed is that you will not
modify an VEDeviceArray for the duration of the current kernel.

This API can only be used on devices with compute capability 3.5 or higher.

!!! warning
    Experimental API. Subject to change without deprecation.
"""
struct Const{T,N} <: DenseArray{T,N}
    a::VEDeviceArray{T,N}
end
Base.Experimental.Const(A::VEDeviceArray) = Const(A)

Base.IndexStyle(::Type{<:Const}) = IndexLinear()
Base.size(C::Const) = size(C.a)
Base.axes(C::Const) = axes(C.a)
Base.@propagate_inbounds Base.getindex(A::Const, i1::Int) = const_arrayref(A.a, i1)

# deprecated
Base.@propagate_inbounds ldg(A::VEDeviceArray, i1::Integer) = const_arrayref(A, Int(i1))


## other

Base.show(io::IO, a::VEDeviceVector) =
    print(io, "$(length(a))-element device array at $(pointer(a))")
Base.show(io::IO, a::VEDeviceArray) =
    print(io, "$(join(a.shape, '×')) device array at $(pointer(a))")

Base.show(io::IO, mime::MIME"text/plain", a::VEDeviceArray) = show(io, a)

@inline function Base.iterate(A::VEDeviceArray, i=1)
    if (i % UInt) - 1 < length(A)
        (@inbounds A[i], i + 1)
    else
        nothing
    end
end
