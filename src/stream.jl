# Stream management

export VEStream, VEDefaultStream, synchronize

using .VEDA: VEDAstream, vedaStreamSynchronize, ERROR_VEO_COMMAND_EXCEPTION, ERROR_VEO_COMMAND_ERROR

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

Wait until a stream's tasks are completed. Return nothing.
Throw an exception if something went very wrong.
"""
@inline function synchronize(s::VEStream)
    err = vedaStreamSynchronize(s.handle)
    if err == ERROR_VEO_COMMAND_EXCEPTION
        throw(VEContextException("VE context died with an exception"))
    elseif err == ERROR_VEO_COMMAND_ERROR
        throw(VEOCommandError("VH side VEO command error"))
    end
end

@inline synchronize() = synchronize(VEDefaultStream())
