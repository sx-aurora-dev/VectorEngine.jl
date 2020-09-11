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
    API.vedaArgsSetF32(args.handle, idx - 1, val)
    val
end

function Base.setindex!(args::VEArgs, val::Float64, idx::Integer)
    API.vedaArgsSetF64(args.handle, idx - 1, val)
    val
end

function Base.setindex!(args::VEArgs, val::Int8, idx::Integer)
    API.vedaArgsSetI8(args.handle, idx - 1, val)
    val
end

function Base.setindex!(args::VEArgs, val::Int16, idx::Integer)
    API.vedaArgsSetI16(args.handle, idx - 1, val)
    val
end

function Base.setindex!(args::VEArgs, val::Int32, idx::Integer)
    API.vedaArgsSetI32(args.handle, idx - 1, val)
    val
end

function Base.setindex!(args::VEArgs, val::Int64, idx::Integer)
    API.vedaArgsSetI64(args.handle, idx - 1, val)
    val
end

function Base.setindex!(args::VEArgs, val::UInt8, idx::Integer)
    API.vedaArgsSetU8(args.handle, idx - 1, val)
    val
end

function Base.setindex!(args::VEArgs, val::UInt16, idx::Integer)
    API.vedaArgsSetU16(args.handle, idx - 1, val)
    val
end

function Base.setindex!(args::VEArgs, val::UInt32, idx::Integer)
    API.vedaArgsSetU32(args.handle, idx - 1, val)
    val
end

function Base.setindex!(args::VEArgs, val::UInt64, idx::Integer)
    API.vedaArgsSetU64(args.handle, idx - 1, val)
    val
end

# Pass string variables on stack. Expect Ptr{...} on the VE side.
# - immutable, therefore only INTENT_IN
function Base.setindex!(args::VEArgs, val::T, idx::Integer) where {T<:AbstractString}
    push!(args.objs, val)
    API.vedaArgsSetStack(args.handle, idx - 1, Base.unsafe_convert(Ptr{Cvoid}, pointer(val)),
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
    if isprimitivetype(T) # reinterpret to Unsigned to get calling convention right
        Tunsigned = equivalent_uint(T)
        if Tunsigned !== nothing
            args[idx] = reinterpret(Tunsigned, val)
            return val
        end
    end
    if (isstructtype(T) || isprimitivetype(T)) && Base.datatype_pointerfree(T) # Pointers within structs can not be de-referenced
        intent = ismutable(val) ? API.VEDA_ARGS_INTENT_INOUT : API.VEDA_ARGS_INTENT_IN
        ref = Ref(val)
        push!(args.objs, ref) # root the reference
        API.vedaArgsSetStack(args.handle, idx - 1, ref, intent, sizeof(T))
        val
    else
        error("VEArgs could not handle $T")
    end
end

# @inline function set_arg!(veargs::VEArgs, ::Type{T}, val, idx::Integer) where T
#     push!(veargs.objs, val) # Root the value
#     veargs[idx] = Base.unsafe_convert(T,  Base.cconvert(T, val))
# end

# convert the argument values to match the kernel's signature (specified by the user)
# (this mimics `lower-ccall` in julia-syntax.scm)
@generated function convert_args(veargs, ::Type{tt}, args...) where {tt}
    types = tt.parameters

    ex = quote
        Base.@_inline_meta
    end

    for i in 1:length(args)
        # push!(ex.args, :(set_arg!(veargs, $(types[i]), args[$i], $i)))
        push!(ex.args, :(veargs[$i] = args[$i]))
    end

    return ex
end

function vecall(func::VEFunction, tt, args...; stream = C_NULL)
    veargs = VEArgs()
    @show args
    convert_args(veargs, tt, args...)

    # TOOD: Can we add a callback that will do args cleanup?
    err = API.vedaLaunchKernelEx(func.handle, stream, veargs.handle, #=destroyArgs=# true)
    err, veargs
end
