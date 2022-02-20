# VE pointer types

export VEPtr, PtrOrVEPtr, VEArrayPtr, VE_NULL, VERef, RefOrVERef


#
# VE device pointer
#

# FIXME: should be called VEDevicePtr...

"""
    VEPtr{T}

A memory address that refers to data of type `T` that is accessible from the VE. A `VEPtr`
is ABI compatible with regular `Ptr` objects, e.g. it can be used to `ccall` a function that
expects a `Ptr` to VE memory, but it prevents erroneous conversions between the two.
"""
VEPtr

primitive type VEPtr{T} 64 end

# constructor
VEPtr{T}(x::Union{Int,UInt,VEPtr}) where {T} = Base.bitcast(VEPtr{T}, x)

const VE_NULL = VEPtr{Cvoid}(0)


## getters

Base.eltype(::Type{<:VEPtr{T}}) where {T} = T


## conversions

# to and from integers
## pointer to integer
Base.convert(::Type{T}, x::VEPtr) where {T<:Integer} = T(UInt(x))
## integer to pointer
Base.convert(::Type{VEPtr{T}}, x::Union{Int,UInt}) where {T} = VEPtr{T}(x)
Int(x::VEPtr)  = Base.bitcast(Int, x)
UInt(x::VEPtr) = Base.bitcast(UInt, x)

# between regular and VE pointers
Base.convert(::Type{Ptr{T}}, p::VEPtr) where {T} = Base.bitcast(Ptr{T}, p)
Base.unsafe_convert(::Type{Ptr{T}}, x::VEPtr) where {T} = convert(Ptr{T}, x)
Base.convert(::Type{VEPtr{T}}, p::Ptr{T}) where {T} = Base.bitcast(Ptr{T}, p)
Base.unsafe_convert(::Type{VEPtr{T}}, x::Ptr{T}) where {T} = convert(VEPtr{T}, x)

# between VE pointers
Base.convert(::Type{VEPtr{T}}, p::VEPtr) where {T} = Base.bitcast(VEPtr{T}, p)

# defer conversions to unsafe_convert
Base.cconvert(::Type{<:VEPtr}, x) = x

# fallback for unsafe_convert
Base.unsafe_convert(::Type{P}, x::VEPtr) where {P<:VEPtr} = convert(P, x)


## limited pointer arithmetic & comparison

Base.isequal(x::VEPtr, y::VEPtr) = (x === y)
Base.isless(x::VEPtr{T}, y::VEPtr{T}) where {T} = x < y

Base.:(==)(x::VEPtr, y::VEPtr) = UInt(x) == UInt(y)
Base.:(<)(x::VEPtr,  y::VEPtr) = UInt(x) < UInt(y)
Base.:(-)(x::VEPtr,  y::VEPtr) = UInt(x) - UInt(y)

Base.:(+)(x::VEPtr, y::Integer) = oftype(x, Base.add_ptr(UInt(x), (y % UInt) % UInt))
Base.:(-)(x::VEPtr, y::Integer) = oftype(x, Base.sub_ptr(UInt(x), (y % UInt) % UInt))
Base.:(+)(x::Integer, y::VEPtr) = y + x



#
# Host or device pointer
#

"""
    PtrOrVEPtr{T}

A special pointer type, ABI-compatible with both `Ptr` and `VEPtr`, for use in `ccall`
expressions to convert values to either a VE or a CPU type (in that order). This is
required for VEDA APIs which accept pointers that either point to host or device memory.
"""
PtrOrVEPtr


primitive type PtrOrVEPtr{T} 64 end

function Base.cconvert(::Type{PtrOrVEPtr{T}}, val) where {T}
    # `cconvert` is always implemented for both `Ptr` and `VEPtr`, so pick the first result
    # that has done an actual conversion

    ve_val = Base.cconvert(VEPtr{T}, val)
    if ve_val !== val
        return ve_val
    end

    cpu_val = Base.cconvert(Ptr{T}, val)
    if cpu_val !== val
        return cpu_val
    end

    return val
end

function Base.unsafe_convert(::Type{PtrOrVEPtr{T}}, val) where {T}
    ptr = if Core.Compiler.return_type(Base.unsafe_convert,
                                       Tuple{Type{Ptr{T}}, typeof(val)}) !== Union{}
        Base.unsafe_convert(Ptr{T}, val)
    elseif Core.Compiler.return_type(Base.unsafe_convert,
                                     Tuple{Type{VEPtr{T}}, typeof(val)}) !== Union{}
        Base.unsafe_convert(VEPtr{T}, val)
    else
        throw(ArgumentError("cannot convert to either a host or device pointer"))
    end

    return Base.bitcast(PtrOrVEPtr{T}, ptr)
end

#
# Device reference objects
#

primitive type VERef{T} 64 end

# general methods for VERef{T} type
Base.eltype(x::Type{<:VERef{T}}) where {T} = @isdefined(T) ? T : Any

Base.convert(::Type{VERef{T}}, x::VERef{T}) where {T} = x

# conversion or the actual ccall
Base.unsafe_convert(::Type{VERef{T}}, x::VERef{T}) where {T} = Base.bitcast(VERef{T}, Base.unsafe_convert(VEPtr{T}, x))
Base.unsafe_convert(::Type{VERef{T}}, x) where {T} = Base.bitcast(VERef{T}, Base.unsafe_convert(VEPtr{T}, x))

# VERef from literal pointer
Base.convert(::Type{VERef{T}}, x::VEPtr{T}) where {T} = x

# indirect constructors using VERef
Base.convert(::Type{VERef{T}}, x) where {T} = VERef{T}(x)


#
# VE array pointer
#

primitive type VEArrayPtr{T} 64 end

# constructor
VEArrayPtr{T}(x::Union{Int,UInt,VEArrayPtr}) where {T} = Base.bitcast(VEArrayPtr{T}, x)


## getters

Base.eltype(::Type{<:VEArrayPtr{T}}) where {T} = T


## conversions

# to and from integers
## pointer to integer
Base.convert(::Type{T}, x::VEArrayPtr) where {T<:Integer} = T(UInt(x))
## integer to pointer
Base.convert(::Type{VEArrayPtr{T}}, x::Union{Int,UInt}) where {T} = VEArrayPtr{T}(x)
Int(x::VEArrayPtr)  = Base.bitcast(Int, x)
UInt(x::VEArrayPtr) = Base.bitcast(UInt, x)

# between regular and CUDA pointers
Base.convert(::Type{<:Ptr}, p::VEArrayPtr) =
    throw(ArgumentError("cannot convert a GPU array pointer to a CPU pointer"))

# between CUDA array pointers
Base.convert(::Type{VEArrayPtr{T}}, p::VEArrayPtr) where {T} = Base.bitcast(VEArrayPtr{T}, p)

# defer conversions to unsafe_convert
Base.cconvert(::Type{<:VEArrayPtr}, x) = x

# fallback for unsafe_convert
Base.unsafe_convert(::Type{P}, x::VEArrayPtr) where {P<:VEArrayPtr} = convert(P, x)


## limited pointer arithmetic & comparison

Base.isequal(x::VEArrayPtr, y::VEArrayPtr) = (x === y)
Base.isless(x::VEArrayPtr{T}, y::VEArrayPtr{T}) where {T} = x < y

Base.:(==)(x::VEArrayPtr, y::VEArrayPtr) = UInt(x) == UInt(y)
Base.:(<)(x::VEArrayPtr,  y::VEArrayPtr) = UInt(x) < UInt(y)
Base.:(-)(x::VEArrayPtr,  y::VEArrayPtr) = UInt(x) - UInt(y)

Base.:(+)(x::VEArrayPtr, y::Integer) = oftype(x, Base.add_ptr(UInt(x), (y % UInt) % UInt))
Base.:(-)(x::VEArrayPtr, y::Integer) = oftype(x, Base.sub_ptr(UInt(x), (y % UInt) % UInt))
Base.:(+)(x::Integer, y::VEArrayPtr) = y + x


#
## VERef object backed by an array at index i
#

struct VERefArray{T,A<:AbstractArray{T}} <: Ref{T}
    x::A
    i::Int
    VERefArray{T,A}(x,i) where {T,A<:AbstractArray{T}} = new(x,i)
end
VERefArray{T}(x::AbstractArray{T}, i::Int=1) where {T} = VERefArray{T,typeof(x)}(x, i)
VERefArray(x::AbstractArray{T}, i::Int=1) where {T} = VERefArray{T}(x, i)
Base.convert(::Type{VERef{T}}, x::AbstractArray{T}) where {T} = VERefArray(x, 1)

function Base.unsafe_convert(P::Type{VEPtr{T}}, b::VERefArray{T}) where T
    return pointer(b.x, b.i)
end
function Base.unsafe_convert(P::Type{VEPtr{Any}}, b::VERefArray{Any})
    return convert(P, pointer(b.x, b.i))
end
Base.unsafe_convert(::Type{VEPtr{Cvoid}}, b::VERefArray{T}) where {T} =
    convert(VEPtr{Cvoid}, Base.unsafe_convert(VEPtr{T}, b))

#
## Union with all VERef 'subtypes'
#

const VERefs{T} = Union{VEPtr{T}, VERefArray{T}}

## RefOrVERef

primitive type RefOrVERef{T} 64 end

Base.convert(::Type{RefOrVERef{T}}, x::Union{RefOrVERef{T}, Ref{T}, VERef{T}, VERefs{T}}) where {T} = x

# prefer conversion to CPU ref: this is generally cheaper
Base.convert(::Type{RefOrVERef{T}}, x) where {T} = Ref{T}(x)
Base.unsafe_convert(::Type{RefOrVERef{T}}, x::Ref{T}) where {T} =
    Base.bitcast(RefOrVERef{T}, Base.unsafe_convert(Ptr{T}, x))
Base.unsafe_convert(::Type{RefOrVERef{T}}, x) where {T} =
    Base.bitcast(RefOrVERef{T}, Base.unsafe_convert(Ptr{T}, x))

# support conversion from VE device ref
Base.unsafe_convert(::Type{RefOrVERef{T}}, x::VERefs{T}) where {T} =
    Base.bitcast(RefOrVERef{T}, Base.unsafe_convert(VEPtr{T}, x))

# support conversion from arrays
Base.convert(::Type{RefOrVERef{T}}, x::Array{T}) where {T} = convert(Ref{T}, x)
Base.convert(::Type{RefOrVERef{T}}, x::AbstractArray{T}) where {T} = convert(VERef{T}, x)
Base.unsafe_convert(P::Type{RefOrVERef{T}}, b::VERefArray{T}) where T =
    Base.bitcast(RefOrVERef{T}, Base.unsafe_convert(VERef{T}, b))
