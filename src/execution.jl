struct HostKernel{F,TT}
    mod::VEModule
    fun::VEFunction
end

@generated function call(kernel::HostKernel{F,TT}, args...; call_kwargs...) where {F,TT}
    sig = Base.signature_type(F, TT)
    args = (:F, (:( args[$i] ) for i in 1:length(args))...)

    # filter out ghost arguments that shouldn't be passed
    to_pass = map(!isghosttype, sig.parameters)
    call_t =                  Type[x[1] for x in zip(sig.parameters,  to_pass) if x[2]]
    call_args = Union{Expr,Symbol}[x[1] for x in zip(args, to_pass)            if x[2]]

    # replace non-isbits arguments (they should be unused, or compilation would have failed)
    # alternatively, allow `launch` with non-isbits arguments.
    for (i,dt) in enumerate(call_t)
        if !isbitstype(dt)
            # Enable passing non-isbitstype on stack
            # TODO: find better way to identify types that actually can be passed
            #call_t[i] = Ptr{Any}
            #call_args[i] = :C_NULL
        end
    end

    # finalize types
    call_tt = Base.to_tuple_type(call_t)

    quote
        Base.@_inline_meta

        vecall(kernel, $call_tt, $(call_args...); call_kwargs...)
    end
end

isghosttype(dt) = !dt.mutable && sizeof(dt) == 0

# old # function vefunction(f::Core.Function, tt::Type=Tuple{}; name=nothing, kernel=true, kwargs...)
# old #     source = FunctionSpec(f, tt, kernel, name)
# old #     GPUCompiler.cached_compilation(_vefunction, source; kwargs...)::HostKernel{f,tt}
# old # end
# old # 
# old # # actual compilation
# old # function _vefunction(source::FunctionSpec; kwargs...)
# old #     # compile to GCN
# old #     target = VECompilerTarget()
# old #     params = VECompilerParams()
# old #     job = CompilerJob(target, source, params)
# old #     obj, kernel_fn, undefined_fns, undefined_gbls = GPUCompiler.compile(:obj, job)
# old # 
# old #     # create executable and kernel
# old #     obj = codeunits(obj)
# old #     mod = VEModule(obj)
# old #     fun = VEFunction(mod, kernel_fn)
# old #     kernel = HostKernel{source.f,source.tt}(mod, fun)
# old # 
# old #     return kernel
# old # end

"""
    vefunction(f, tt=Tuple{}; kwargs...)

Low-level interface to compile a function invocation for the currently-active GPU, returning
a callable kernel object. For a higher-level interface, use [`@roc`](@ref).

The following keyword arguments are supported:
- `name`: overrides the name that the kernel will have in the generated code
- `device`: chooses which device to compile the kernel for
- `global_hooks`: specifies maps from global variable name to initializer hook

The output of this function is automatically cached, i.e. you can simply call `rocfunction`
in a hot path without degrading performance. New code will be generated automatically, when
function definitions change, or when different types or keyword arguments are provided.
"""
function vefunction(f::Core.Function, tt::Type=Tuple{}; name=nothing, device=0, global_hooks=NamedTuple(), kwargs...)
    source = FunctionSpec(f, tt, true, name)
    cache = get!(()->Dict{UInt,Any}(), vefunction_cache, device)
    #isa = default_isa(device)
    target = VECompilerTarget()
    params = VECompilerParams()
    job = CompilerJob(target, source, params)
    GPUCompiler.cached_compilation(cache, job, vefunction_compile, vefunction_link)::HostKernel{f,tt}
end

const vefunction_cache = Dict{UInt,Dict{UInt,Any}}()


function vefunction_compile(@nospecialize(job::CompilerJob))
    # compile
    method_instance, mi_meta = GPUCompiler.emit_julia(job)
    ir, ir_meta = GPUCompiler.emit_llvm(job, method_instance)
    kernel = ir_meta.entry

    obj, obj_meta = GPUCompiler.emit_asm(job, ir; format=LLVM.API.LLVMObjectFile)

    # find undefined globals and calculate sizes
    globals = map(gbl->Symbol(LLVM.name(gbl))=>llvmsize(eltype(llvmtype(gbl))),
                  filter(x->isextinit(x), collect(LLVM.globals(ir))))
    entry = LLVM.name(kernel)
    dispose(ir)

    return (;obj, entry, globals)
end
function vefunction_link(@nospecialize(job::CompilerJob), compiled)
    device = job.params.device
    global_hooks = job.params.global_hooks
    obj, entry, globals = compiled.obj, compiled.entry, compiled.globals

    # create executable and kernel
    obj = codeunits(obj)
    #exe = create_executable(device, entry, obj; globals=globals)
    mod = VEModule(exe)
    fun = VEFunction(mod, entry)
    kernel = HostKernel{job.source.f,job.source.tt}(mod, fun)

    # initialize globals from hooks
    for gname in first.(globals)
        hook = nothing
        if haskey(default_global_hooks, gname)
            hook = default_global_hooks[gname]
        elseif haskey(global_hooks, gname)
            hook = global_hooks[gname]
        end
        if hook !== nothing
            @debug "Initializing global $gname"
            gbl = get_global(exe, gname)
            hook(gbl, mod, device)
        else
            @debug "Uninitialized global $gname"
            continue
        end
    end

    return kernel
end



# https://github.com/JuliaLang/julia/issues/14919
(kernel::HostKernel)(args...; kwargs...) = call(kernel, args...; kwargs...)

@inline function vecall(kernel::HostKernel, tt, args...; kwargs...)
    VEDA.vecall(kernel.fun, tt, args...; kwargs...,)
end

@inline function vesync(; kwargs...)
    VEDA.vesync(; kwargs...)
end
