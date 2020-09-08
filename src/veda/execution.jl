struct VEArgs
    handle::API.VEDAargs
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

# VEDAresult	vedaArgsSetPtr				(VEDAargs args, const int idx, const VEDAdeviceptr value);
# VEDAresult	vedaArgsSetStack			(VEDAargs args, const int idx, void* ptr, VEDAargs_intent intent, const size_t size);

function vecall(func::VEFunction, tt, args...; stream = C_NULL)
    r_args = Ref{API.VEDAargs}()
    API.vedaArgsCreate(r_args)
    veargs = VEArgs(r_args[])

    # TODO: Support arbitrary structs
    #       https://github.com/JuliaGPU/CUDA.jl/blob/edadef79a7be0604eb26ccd1f770771e334972d7/lib/cudadrv/execution.jl#L136-L140
    for (i, arg) in enumerate(args)
        veargs[i] = arg
    end

    API.vedaLaunchKernelEx(func.handle, stream, veargs.handle, #=destroyArgs=# true)
end

