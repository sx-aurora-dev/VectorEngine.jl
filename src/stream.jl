# Stream management

export VEStream, VEDefaultStream

import .VEDA.API: VEDAstream

mutable struct VEStream
    handle::VEDAstream
end

Base.unsafe_convert(::Type{VEDAstream}, s::VEStream) = s.handle
Base.convert(::Type{VEDAstream}, s::VEStream) = s.handle

Base.:(==)(a::VEStream, b::VEStream) = a.handle == b.handle
Base.hash(s::VEStream, h::UInt) = hash(s.handle, h)

"""
    VEDefaultStream()

Return the default stream.
"""
@inline VEDefaultStream() = VEStream(convert(VEDAstream, C_NULL))

"""
    synchronize(s::VEStream)

Wait until a stream's tasks are completed.
"""
synchronize(s::VEStream) = vedaStreamSynchronize(s)
