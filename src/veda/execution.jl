struct VEArgs
    handle::API.VEDAargs
    objs::Base.IdSet
    function VEArgs()
        r_handle = Ref{API.VEDAargs}()
        API.vedaArgsCreate(r_handle)
        return new(r_handle[], Base.IdSet())
    end
end

function Base.setindex!(args::VEArgs, val::Float32, idx::Integer)
    API.vedaArgsSetF32(args.handle, idx, val)
    val
end

function Base.setindex!(args::VEArgs, val::Float64, idx::Integer)
    println("setindex Float64 $idx")
    API.vedaArgsSetF64(args.handle, idx, val)
    val
end

function Base.setindex!(args::VEArgs, val::Int8, idx::Integer)
    API.vedaArgsSetI8(args.handle, idx, val)
    val
end

function Base.setindex!(args::VEArgs, val::Int16, idx::Integer)
    API.vedaArgsSetI16(args.handle, idx, val)
    val
end

function Base.setindex!(args::VEArgs, val::Int32, idx::Integer)
    API.vedaArgsSetI32(args.handle, idx, val)
    val
end

function Base.setindex!(args::VEArgs, val::Int64, idx::Integer)
    println("setindex Int64 $idx")
    API.vedaArgsSetI64(args.handle, idx, val)
    val
end

function Base.setindex!(args::VEArgs, val::UInt8, idx::Integer)
    API.vedaArgsSetU8(args.handle, idx, val)
    val
end

function Base.setindex!(args::VEArgs, val::UInt16, idx::Integer)
    API.vedaArgsSetU16(args.handle, idx, val)
    val
end

function Base.setindex!(args::VEArgs, val::UInt32, idx::Integer)
    API.vedaArgsSetU32(args.handle, idx, val)
    val
end

function Base.setindex!(args::VEArgs, val::UInt64, idx::Integer)
    API.vedaArgsSetU64(args.handle, idx, val)
    val
end

# Pass string variables on stack. Expect Ptr{...} on the VE side.
# - immutable, therefore only INTENT_IN
function Base.setindex!(args::VEArgs, val::T, idx::Integer) where {T<:AbstractString}
    push!(args.objs, val)
    API.vedaArgsSetStack(args.handle, idx, Base.unsafe_convert(Ptr{Cvoid}, pointer(val)),
                         API.VEDA_ARGS_INTENT_IN, sizeof(val))
    val
end

function equivalent_uint(::Type{T}) where T
    if sizeof(T) == 1
        return UInt8
    elseif sizeof(T) == 2
        return UInt16
    elseif sizeof(T) == 4
        return UInt32
    elseif sizeof(T) == 8
        return UInt64
    else
        return nothing
    end
end

# Pass structs on stack. If mutable, modified elements can be passed back, too.
function Base.setindex!(args::VEArgs, val::T, idx::Integer) where {T}
    @debug "setindex idx=$idx T=$T val=$val"
    #if isprimitivetype(T) # reinterpret to Unsigned to get calling convention right
    #    print("reinterpret to Unsigned: "); @show idx T val
    #    Tunsigned = equivalent_uint(T)
    #    if Tunsigned !== nothing
    #        args[idx] = reinterpret(Tunsigned, val)
    #        return val
    #    end
    #end
    if isstructtype(T) && Base.datatype_pointerfree(T) # Pointers within structs can not be de-referenced
        @debug "seems to be a struct"
        intent = ismutable(val) ? API.VEDA_ARGS_INTENT_INOUT : API.VEDA_ARGS_INTENT_IN
        ref = Ref(val)
        push!(args.objs, ref) # root the reference
        ptr = Base.unsafe_convert(Ptr{Cvoid}, ref)
        API.vedaArgsSetStack(args.handle, idx, ptr, intent, sizeof(T))
        val
    elseif T <: Base.RefValue && isassigned(val)
        @debug "seems to be a refvalue"
        intent = ismutable(val[]) ? API.VEDA_ARGS_INTENT_INOUT : API.VEDA_ARGS_INTENT_IN
        push!(args.objs, val) # root the reference
        ptr = Base.unsafe_convert(Ptr{Cvoid}, val)
        API.vedaArgsSetStack(args.handle, idx, ptr, intent, sizeof(val[]))
        val
    else
        error("VEArgs could not handle $T")
    end
end

# convert the argument values to match the kernel's signature (specified by the user)
# (this mimics `lower-ccall` in julia-syntax.scm)
@generated function convert_args(veargs, ::Type{tt}, args...) where {tt}
    types = tt.parameters

    ex = quote
        Base.@_inline_meta
    end

    # first arg is the kernel function, skip that
    for i in 2:length(args)
        push!(ex.args, :(veargs[$(i-2)] = args[$i]))
    end

    return ex
end

function vecall(func::VEFunction, tt, args...; stream = C_NULL)
    veargs = VEArgs()
    #@show args
    convert_args(veargs, tt, args...)

    # TOOD: Can we add a callback that will do args cleanup?
    err = API.vedaLaunchKernelEx(func.handle, stream, veargs.handle, #=destroyArgs=# true, 0)
    if err != API.VEDA_SUCCESS
        throw(VEOCommandError("kernel launch failed"))
    end
    err, veargs
end

struct VEContextException <: Exception
    reason::String
end
struct VEOCommandError <: Exception
    reason::String
end

# synchronize a stream
# throw an exception if something went very wrong
function vesync(; stream = C_NULL)
    err = API.vedaStreamSynchronize(stream)
    if err == API.VEDA_ERROR_VEO_COMMAND_EXCEPTION
        throw(VEContextException("VE context died with an exception"))
    elseif err == API.VEDA_ERROR_VEO_COMMAND_ERROR
        throw(VEOCommandError("VH side VEO command error"))
    end
end
