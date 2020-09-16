# Stream management

export VeStream, VeDefaultStream

import .VEDA.API: VEDAstream

mutable struct VeStream
    handle::VEDAstream
end

Base.unsafe_convert(::Type{VEDAstream}, s::VeStream) = s.handle
Base.convert(::Type{VEDAstream}, s::VeStream) = s.handle

Base.:(==)(a::VeStream, b::VeStream) = a.handle == b.handle
Base.hash(s::VeStream, h::UInt) = hash(s.handle, h)

"""
    VeDefaultStream()

Return the default stream.
"""
@inline VeDefaultStream() = VeStream(convert(VEDAstream, C_NULL))

"""
    synchronize(s::VeStream)

Wait until a stream's tasks are completed.
"""
synchronize(s::VeStream) = vedaStreamSynchronize(s)
