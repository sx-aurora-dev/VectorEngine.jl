# VE pointer types

export VePtr, PtrOrVePtr, VeArrayPtr, VE_NULL


#
# VE device pointer
#

# FIXME: should be called VeDevicePtr...

"""
    VePtr{T}

A memory address that refers to data of type `T` that is accessible from the VE. A `VePtr`
is ABI compatible with regular `Ptr` objects, e.g. it can be used to `ccall` a function that
expects a `Ptr` to VE memory, but it prevents erroneous conversions between the two.
"""
VePtr

primitive type VePtr{T} 64 end

# constructor
VePtr{T}(x::Union{Int,UInt,VePtr}) where {T} = Base.bitcast(VePtr{T}, x)

const VE_NULL = VePtr{Cvoid}(0)


## getters

Base.eltype(::Type{<:VePtr{T}}) where {T} = T


## conversions

# to and from integers
## pointer to integer
Base.convert(::Type{T}, x::VePtr) where {T<:Integer} = T(UInt(x))
## integer to pointer
Base.convert(::Type{VePtr{T}}, x::Union{Int,UInt}) where {T} = VePtr{T}(x)
Int(x::VePtr)  = Base.bitcast(Int, x)
UInt(x::VePtr) = Base.bitcast(UInt, x)

# between regular and VE pointers
Base.convert(::Type{Ptr{T}}, p::VePtr) where {T} = Base.bitcast(Ptr{T}, p)
Base.unsafe_convert(::Type{Ptr{T}}, x::VePtr) where {T} = convert(Ptr{T}, x)

# between VE pointers
Base.convert(::Type{VePtr{T}}, p::VePtr) where {T} = Base.bitcast(VePtr{T}, p)

# defer conversions to unsafe_convert
Base.cconvert(::Type{<:VePtr}, x) = x

# fallback for unsafe_convert
Base.unsafe_convert(::Type{P}, x::VePtr) where {P<:VePtr} = convert(P, x)


## limited pointer arithmetic & comparison

Base.isequal(x::VePtr, y::VePtr) = (x === y)
Base.isless(x::VePtr{T}, y::VePtr{T}) where {T} = x < y

Base.:(==)(x::VePtr, y::VePtr) = UInt(x) == UInt(y)
Base.:(<)(x::VePtr,  y::VePtr) = UInt(x) < UInt(y)
Base.:(-)(x::VePtr,  y::VePtr) = UInt(x) - UInt(y)

Base.:(+)(x::VePtr, y::Integer) = oftype(x, Base.add_ptr(UInt(x), (y % UInt) % UInt))
Base.:(-)(x::VePtr, y::Integer) = oftype(x, Base.sub_ptr(UInt(x), (y % UInt) % UInt))
Base.:(+)(x::Integer, y::VePtr) = y + x



#
# Host or device pointer
#

"""
    PtrOrVePtr{T}

A special pointer type, ABI-compatible with both `Ptr` and `VePtr`, for use in `ccall`
expressions to convert values to either a VE or a CPU type (in that order). This is
required for VEDA APIs which accept pointers that either point to host or device memory.
"""
PtrOrVePtr


primitive type PtrOrVePtr{T} 64 end

function Base.cconvert(::Type{PtrOrVePtr{T}}, val) where {T}
    # `cconvert` is always implemented for both `Ptr` and `VePtr`, so pick the first result
    # that has done an actual conversion

    ve_val = Base.cconvert(VePtr{T}, val)
    if ve_val !== val
        return ve_val
    end

    cpu_val = Base.cconvert(Ptr{T}, val)
    if cpu_val !== val
        return cpu_val
    end

    return val
end

function Base.unsafe_convert(::Type{PtrOrVePtr{T}}, val) where {T}
    # FIXME: this is expensive; optimize using isapplicable?
    ptr = try
        Base.unsafe_convert(Ptr{T}, val)
    catch
        try
            Base.unsafe_convert(VePtr{T}, val)
        catch
            throw(ArgumentError("cannot convert to either a CPU or VE pointer"))
        end
    end
    return Base.bitcast(PtrOrVePtr{T}, ptr)
end


#
# VE array pointer
#

primitive type VeArrayPtr{T} 64 end

# constructor
VeArrayPtr{T}(x::Union{Int,UInt,VeArrayPtr}) where {T} = Base.bitcast(VeArrayPtr{T}, x)


## getters

Base.eltype(::Type{<:VeArrayPtr{T}}) where {T} = T


## conversions

# to and from integers
## pointer to integer
Base.convert(::Type{T}, x::VeArrayPtr) where {T<:Integer} = T(UInt(x))
## integer to pointer
Base.convert(::Type{VeArrayPtr{T}}, x::Union{Int,UInt}) where {T} = VeArrayPtr{T}(x)
Int(x::VeArrayPtr)  = Base.bitcast(Int, x)
UInt(x::VeArrayPtr) = Base.bitcast(UInt, x)

# between regular and VE pointers
Base.convert(::Type{<:Ptr}, p::VeArrayPtr) =
    throw(ArgumentError("cannot convert a VE array pointer to a CPU pointer"))

# between VE array pointers
Base.convert(::Type{VeArrayPtr{T}}, p::VeArrayPtr) where {T} = Base.bitcast(VeArrayPtr{T}, p)

# defer conversions to unsafe_convert
Base.cconvert(::Type{<:VeArrayPtr}, x) = x

# fallback for unsafe_convert
Base.unsafe_convert(::Type{P}, x::VeArrayPtr) where {P<:VeArrayPtr} = convert(P, x)
