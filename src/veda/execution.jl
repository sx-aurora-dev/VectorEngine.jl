struct VEArgs
    handle::API.VEDAargs
end

function Base.setindex(args::VEArgs, idx::Int, val::Float32)
    API.vedaArgsSetF32(args.handle, idx, val)
    val
end

function Base.setindex(args::VEArgs, idx::Int, val::Float64)
    API.vedaArgsSetF64(args.handle, idx, val)
    val
end

function Base.setindex(args::VEArgs, idx::Int, val::Int8)
    API.vedaArgsSetI8(args.handle, idx, val)
    val
end

function Base.setindex(args::VEArgs, idx::Int, val::Int16)
    API.vedaArgsSetI16(args.handle, idx, val)
    val
end

function Base.setindex(args::VEArgs, idx::Int, val::Int32)
    API.vedaArgsSetI32(args.handle, idx, val)
    val
end

function Base.setindex(args::VEArgs, idx::Int, val::Int64)
    API.vedaArgsSetI64(args.handle, idx, val)
    val
end

function Base.setindex(args::VEArgs, idx::Int, val::UInt8)
    API.vedaArgsSetU8(args.handle, idx, val)
    val
end

function Base.setindex(args::VEArgs, idx::Int, val::UInt16)
    API.vedaArgsSetU16(args.handle, idx, val)
    val
end

function Base.setindex(args::VEArgs, idx::Int, val::UInt32)
    API.vedaArgsSetU32(args.handle, idx, val)
    val
end

function Base.setindex(args::VEArgs, idx::Int, val::UInt64)
    API.vedaArgsSetU64(args.handle, idx, val)
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

