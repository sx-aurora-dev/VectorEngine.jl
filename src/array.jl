# host array

export VEArray

@enum ArrayState begin
  ARRAY_UNMANAGED
  ARRAY_MANAGED
  ARRAY_FREED
end

mutable struct VEArray{T,N} <: AbstractGPUArray{T,N}
  buf::Union{Nothing,Mem.Device}
  dims::Dims{N}

  state::ArrayState

  #ctx::VEContext
  #dev::VEDevice

  function VEArray{T,N}(::UndefInitializer, dims::Dims{N}) where {T,N}
    Base.isbitsunion(T) && error("VEArray does not yet support union bits types")
    Base.isbitstype(T)  || error("VEArray only supports bits types") # allocatedinline on 1.3+
    #ctx = context()
    #dev = device()
    buf = Mem.Device(prod(dims) * sizeof(T))          # not needed # , Base.datatype_alignment(T))
    obj = new{T,N}(buf, dims, ARRAY_MANAGED) # add these later # , ctx, dev)
    finalizer(unsafe_free!, obj)
    return obj
  end
end

function unsafe_free!(xs::VEArray)
  # this call should only have an effect once, becuase both the user and the GC can call it
  if xs.state == ARRAY_FREED
    return
  elseif xs.state == ARRAY_UNMANAGED
    throw(ArgumentError("Cannot free an unmanaged buffer."))
  end

  finalize(xs.buf)
  xs.state = ARRAY_FREED

  # the object is dead, so we can also wipe the pointer
  xs.buf = nothing

  return
end

#device(a::VEArray) = a.dev
#context(a::VEArray) = a.ctx


## alias detection

Base.dataids(A::VEArray) = (UInt(pointer(A)),)

Base.unaliascopy(A::VEArray) = copy(A)


## convenience constructors

VEVector{T} = VEArray{T,1}
VEMatrix{T} = VEArray{T,2}
VEVecOrMat{T} = Union{VEVector{T},VEMatrix{T}}

# type and dimensionality specified, accepting dims as series of Ints
VEArray{T,N}(::UndefInitializer, dims::Integer...) where {T,N} = VEArray{T,N}(undef, dims)

# type but not dimensionality specified
VEArray{T}(::UndefInitializer, dims::Dims{N}) where {T,N} = VEArray{T,N}(undef, dims)
VEArray{T}(::UndefInitializer, dims::Integer...) where {T} =
    VEArray{T}(undef, convert(Tuple{Vararg{Int}}, dims))

# empty vector constructor
VEArray{T,1}() where {T} = VEArray{T,1}(undef, 0)

# do-block constructors
for (ctor, tvars) in (:VEArray => (), :(VEArray{T}) => (:T,), :(VEArray{T,N}) => (:T, :N))
  @eval begin
    function $ctor(f::Function, args...) where {$(tvars...)}
      xs = $ctor(args...)
      try
        f(xs)
      finally
        unsafe_free!(xs)
      end
    end
  end
end

Base.similar(a::VEArray{T,N}) where {T,N} = VEArray{T,N}(undef, size(a))
Base.similar(a::VEArray{T}, dims::Base.Dims{N}) where {T,N} = VEArray{T,N}(undef, dims)
Base.similar(a::VEArray, ::Type{T}, dims::Base.Dims{N}) where {T,N} = VEArray{T,N}(undef, dims)

function Base.copy(a::VEArray{T,N}) where {T,N}
  b = similar(a)
  @inbounds copyto!(b, a)
end


## array interface

Base.elsize(::Type{<:VEArray{T}}) where {T} = sizeof(T)

Base.size(x::VEArray) = x.dims
Base.sizeof(x::VEArray) = Base.elsize(x) * length(x)


## derived types

export VEDenseArray, VEDenseVector, VEDenseMatrix, VEDenseVecOrMat,
       VEDenseArray, VEDenseVector, VEDenseMatrix, VEDenseVecOrMat,
       VEWrappedArray, VEWrappedVector, VEWrappedMatrix, VEWrappedVecOrMat

VEContiguousSubArray{T,N,A<:VEArray} = Base.FastContiguousSubArray{T,N,A}

# dense arrays: stored contiguously in memory
VEDenseReinterpretArray{T,N,A<:Union{VEArray,VEContiguousSubArray}} = Base.ReinterpretArray{T,N,S,A} where S
VEDenseReshapedArray{T,N,A<:Union{VEArray,VEContiguousSubArray,VEDenseReinterpretArray}} = Base.ReshapedArray{T,N,A}
DenseSubVEArray{T,N,A<:Union{VEArray,VEDenseReshapedArray,VEDenseReinterpretArray}} = Base.FastContiguousSubArray{T,N,A}
VEDenseArray{T,N} = Union{VEArray{T,N}, DenseSubVEArray{T,N}, VEDenseReshapedArray{T,N}, VEDenseReinterpretArray{T,N}}
VEDenseVector{T} = VEDenseArray{T,1}
VEDenseMatrix{T} = VEDenseArray{T,2}
VEDenseVecOrMat{T} = Union{VEDenseVector{T}, VEDenseMatrix{T}}

# strided arrays
VEStridedSubArray{T,N,A<:Union{VEArray,VEDenseReshapedArray,VEDenseReinterpretArray},
                  I<:Tuple{Vararg{Union{Base.RangeIndex, Base.ReshapedUnitRange,
                                        Base.AbstractCartesianIndex}}}} = SubArray{T,N,A,I}
VEStridedArray{T,N} = Union{VEArray{T,N}, VEStridedSubArray{T,N}, VEDenseReshapedArray{T,N}, VEDenseReinterpretArray{T,N}}
VEStridedVector{T} = VEStridedArray{T,1}
VEStridedMatrix{T} = VEStridedArray{T,2}
VEStridedVecOrMat{T} = Union{VEStridedVector{T}, VEStridedMatrix{T}}

Base.pointer(x::VEStridedArray{T}) where {T} = Base.unsafe_convert(VEPtr{T}, x)
@inline function Base.pointer(x::VEStridedArray{T}, i::Integer) where T
    Base.unsafe_convert(VEPtr{T}, x) + Base._memory_offset(x, i)
end

# wrapped arrays: can be used in kernels
VEWrappedArray{T,N} = Union{VEArray{T,N}, WrappedArray{T,N,VEArray,VEArray{T,N}}}
VEWrappedVector{T} = VEWrappedArray{T,1}
VEWrappedMatrix{T} = VEWrappedArray{T,2}
VEWrappedVecOrMat{T} = Union{VEWrappedVector{T}, VEWrappedMatrix{T}}


## interop with other arrays

@inline function VEArray{T,N}(xs::AbstractArray{<:Any,N}) where {T,N}
  A = VEArray{T,N}(undef, size(xs))
  copyto!(A, convert(Array{T}, xs))
  return A
end

# underspecified constructors
VEArray{T}(xs::AbstractArray{S,N}) where {T,N,S} = VEArray{T,N}(xs)
(::Type{VEArray{T,N} where T})(x::AbstractArray{S,N}) where {S,N} = VEArray{S,N}(x)
VEArray(A::AbstractArray{T,N}) where {T,N} = VEArray{T,N}(A)

# idempotency
VEArray{T,N}(xs::VEArray{T,N}) where {T,N} = xs

# Level Zero references
VERef(x::Any) = VERefArray(VEArray([x]))
VERef{T}(x) where {T} = VERefArray{T}(VEArray(T[x]))
VERef{T}() where {T} = VERefArray(VEArray{T}(undef, 1))


## conversions

Base.convert(::Type{T}, x::T) where T <: VEArray = x


## interop with C libraries

Base.unsafe_convert(::Type{Ptr{T}}, x::VEArray{T}) where {T} =
  throw(ArgumentError("cannot take the host address of a $(typeof(x))"))
Base.unsafe_convert(::Type{VEPtr{T}}, x::VEArray{T}) where {T} = reinterpret(VEPtr{T}, pointer(x.buf))


## interop with GPU arrays

function Base.unsafe_convert(::Type{VEDeviceArray{T,N,AS.Global}}, a::VEDenseArray{T,N}) where {T,N}
    VEDeviceArray{T,N,AS.Global}(size(a), reinterpret(LLVMPtr{T,AS.Global}, a.buf.ptr))
end

Adapt.adapt_storage(::Adaptor, xs::VEArray{T,N}) where {T,N} =
  Base.unsafe_convert(VEDeviceArray{T,N,AS.Global}, xs)

# we materialize ReshapedArray/ReinterpretArray/SubArray/... directly as a device array
Adapt.adapt_structure(::Adaptor, xs::VEDenseArray{T,N}) where {T,N} =
  Base.unsafe_convert(VEDeviceArray{T,N,AS.Global}, xs)

## interop with CPU arrays

# We don't convert isbits types in `adapt`, since they are already
# considered GPU-compatible.

Adapt.adapt_storage(::Type{VEArray}, xs::AbstractArray) =
  isbits(xs) ? xs : convert(VEArray, xs)

# if an element type is specified, convert to it
Adapt.adapt_storage(::Type{<:VEArray{T}}, xs::AbstractArray) where {T} =
  isbits(xs) ? xs : convert(VEArray{T}, xs)

Adapt.adapt_storage(::Type{Array}, xs::VEArray) = convert(Array, xs)

Base.collect(x::VEArray{T,N}) where {T,N} = copyto!(Array{T,N}(undef, size(x)), x)

function Base.copyto!(dest::VEArray{T}, doffs::Integer, src::Array{T}, soffs::Integer,
                      n::Integer) where T
  n==0 && return dest
  @boundscheck checkbounds(dest, doffs)
  @boundscheck checkbounds(dest, doffs+n-1)
  @boundscheck checkbounds(src, soffs)
  @boundscheck checkbounds(src, soffs+n-1)
  unsafe_copyto!(dest, doffs, src, soffs, n)
  return dest
end

Base.copyto!(dest::VEDenseArray{T}, src::Array{T}) where {T} =
    copyto!(dest, 1, src, 1, length(src))

function Base.copyto!(dest::Array{T}, doffs::Integer, src::VEDenseArray{T}, soffs::Integer,
                      n::Integer) where T
  n==0 && return dest
  @boundscheck checkbounds(dest, doffs)
  @boundscheck checkbounds(dest, doffs+n-1)
  @boundscheck checkbounds(src, soffs)
  @boundscheck checkbounds(src, soffs+n-1)
  unsafe_copyto!(dest, doffs, src, soffs, n)
  return dest
end

Base.copyto!(dest::Array{T}, src::VEDenseArray{T}) where {T} =
    copyto!(dest, 1, src, 1, length(src))

function Base.copyto!(dest::VEDenseArray{T}, doffs::Integer, src::VEDenseArray{T}, soffs::Integer,
                      n::Integer) where T
  n==0 && return dest
  @boundscheck checkbounds(dest, doffs)
  @boundscheck checkbounds(dest, doffs+n-1)
  @boundscheck checkbounds(src, soffs)
  @boundscheck checkbounds(src, soffs+n-1)
  #@assert device(dest) == device(src) && context(dest) == context(src)
  unsafe_copyto!(dest, doffs, src, soffs, n)
  return dest
end

Base.copyto!(dest::VEDenseArray{T}, src::VEDenseArray{T}) where {T} =
    copyto!(dest, 1, src, 1, length(src))

function Base.unsafe_copyto!(      # not needed # ctx::ZeContext, dev::ZeDevice,
                             dest::VEDenseArray{T}, doffs, src::Array{T}, soffs, n) where T
  GC.@preserve src dest unsafe_copyto!(pointer(dest, doffs), pointer(src, soffs), n)
  if Base.isbitsunion(T)
    # copy selector bytes
    error("Not implemented")
  end
  return dest
end

function Base.unsafe_copyto!(      # not needed # ctx::ZeContext, dev::ZeDevice,
                             dest::Array{T}, doffs, src::VEDenseArray{T}, soffs, n) where T
  GC.@preserve src dest unsafe_copyto!(pointer(dest, doffs), pointer(src, soffs), n)
  if Base.isbitsunion(T)
    # copy selector bytes
    error("Not implemented")
  end

  # copies to the host are synchronizing
  #synchronize(global_queue(context(src), device(src)))
  vesync()

  return dest
end

function Base.unsafe_copyto!(         # not needed # ctx::ZeContext, dev::ZeDevice,
                             dest::VEDenseArray{T}, doffs, src::VEDenseArray{T}, soffs, n) where T
  GC.@preserve src dest unsafe_copyto!(pointer(dest, doffs), pointer(src, soffs), n)
  if Base.isbitsunion(T)
    # copy selector bytes
    error("Not implemented")
  end
  return dest
end


## utilities

zeros(T::Type, dims...) = fill!(VEArray{T}(undef, dims...), 0)
ones(T::Type, dims...) = fill!(VEArray{T}(undef, dims...), 1)
zeros(dims...) = zeros(Float64, dims...)
ones(dims...) = ones(Float64, dims...)
fill(v, dims...) = fill!(VEArray{typeof(v)}(undef, dims...), v)
fill(v, dims::Dims) = fill!(VEArray{typeof(v)}(undef, dims...), v)

function Base.fill!(A::VEDenseArray{T}, val) where T
  #B = [convert(T, val)]
  #unsafe_fill!(pointer(A), pointer(B), length(A))
  Mem.set!(pointer(A), convert(T, val), length(A))
  A
end


## views

@inline function Base.view(A::VEArray, I::Vararg{Any,N}) where {N}
    J = to_indices(A, I)
    @boundscheck begin
        # Base's boundscheck accesses the indices, so make sure they reside on the CPU.
        # this is expensive, but it's a bounds check after all.
        J_cpu = map(j->adapt(Array, j), J)
        checkbounds(A, J_cpu...)
    end
    J_gpu = map(j->adapt(VEArray, j), J)
    Base.unsafe_view(Base._maybe_reshape_parent(A, Base.index_ndims(J_gpu...)), J_gpu...)
end

#device(a::SubArray) = device(parent(a))
#context(a::SubArray) = context(parent(a))

# contiguous subarrays
function Base.unsafe_convert(::Type{VEPtr{T}}, V::SubArray{T,N,P,<:Tuple{Vararg{Base.RangeIndex}}}) where {T,N,P}
    return Base.unsafe_convert(VEPtr{T}, parent(V)) +
           Base._memory_offset(V.parent, map(first, V.indices)...)
end

# reshaped subarrays
function Base.unsafe_convert(::Type{VEPtr{T}}, V::SubArray{T,N,P,<:Tuple{Vararg{Union{Base.RangeIndex,Base.ReshapedUnitRange}}}}) where {T,N,P}
   return Base.unsafe_convert(VEPtr{T}, parent(V)) +
          (Base.first_index(V)-1)*sizeof(T)
end


## reshape

#device(a::Base.ReshapedArray) = device(parent(a))
#context(a::Base.ReshapedArray) = context(parent(a))

Base.unsafe_convert(::Type{VEPtr{T}}, a::Base.ReshapedArray{T}) where {T} =
  Base.unsafe_convert(VEPtr{T}, parent(a))


## reinterpret

#device(a::Base.ReinterpretArray) = device(parent(a))
#context(a::Base.ReinterpretArray) = context(parent(a))

Base.unsafe_convert(::Type{VEPtr{T}}, a::Base.ReinterpretArray{T,N,S} where N) where {T,S} =
  VPEtr{T}(Base.unsafe_convert(VEPtr{S}, parent(a)))
