# Error type and decoding functionality

export VEError


"""
    VEError(code)
    VEError(code, meta)

Create a VEDA error object with error code `code`. The optional `meta` parameter indicates
whether extra information, such as error logs, is known.
"""
struct VEError <: Exception
    code::VEDAresult
    meta::Any

    VEError(code, meta=nothing) = new(code, meta)
end

Base.convert(::Type{VEDAresult}, err::VEError) = err.code

Base.:(==)(x::VEError,y::VEError) = x.code == y.code

"""
    name(err::VEError)

Gets the string representation of an error code.

```jldoctest
julia> err = VEError(VEDA.VEDAresult_enum(1))
VEError(VEDA_ERROR_INVALID_VALUE)

julia> name(err)
"ERROR_INVALID_VALUE"
```
"""
function name(err::VEError)
    str_ref = Ref{Cstring}()
    vedaGetErrorName(err, str_ref)
    unsafe_string(str_ref[])[6:end]
end

"""
    description(err::VEError)

Gets the string description of an error code.
"""
function description(err::VEError)
    if err.code == -1%UInt32
        "Cannot use the VEDA stub libraries."
    else
        str_ref = Ref{Cstring}()
        vedaGetErrorString(err, str_ref)
        unsafe_string(str_ref[])
    end
end

function Base.showerror(io::IO, err::VEError)
    try
        print(io, "VEDA error: $(description(err)) (code $(reinterpret(Int32, err.code)), $(name(err)))")
    catch
        # we might throw before the library is initialized
        print(io, "VEDA error (code $(reinterpret(Int32, err.code)), $(err.code))")
    end

    if err.meta != nothing
        print(io, "\n")
        print(io, err.meta)
    end
end

Base.show(io::IO, ::MIME"text/plain", err::VEError) = print(io, "VEError($(err.code))")

@enum_without_prefix VEDAresult_enum VEDA_


## API call wrapper

#@inline function initialize_context()
#    prepare_cuda_state()
#    return
#end

# outlined functionality to avoid GC frame allocation
@noinline function throw_api_error(res)
    #if res == ERROR_OUT_OF_MEMORY
    #    throw(OutOfGPUMemoryError())
    #else
        throw(VEError(res))
    #end
end

macro check(ex)
    quote
        res = $(esc(ex))
        if res != SUCCESS
            throw_api_error(res)
        end
        nothing
    end
end
