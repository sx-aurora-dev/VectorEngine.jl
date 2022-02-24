export VERefValue

# Base.RefValue isn't VE compatible, so provide a compatible alternative
mutable struct VERefValue{T} <: Ref{T}
  x::T
  function VERefValue{T}(v::T) where {T}
    return new{T}(v)
  end
end

function VERefValue(v::T) where {T}
  return VERefValue{T}(v)
end

@inline Base.getindex(r::VERefValue) = r.x
@inline function Base.setindex!(r::VERefValue, x)
    r.x = x
    x
end
