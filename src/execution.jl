struct DeviceKernel{F,TT}
    mod::VEModule
    fun::VEFunction
end

@generated function call(kernel::DeviceKernel{F,TT}, args...; call_kwargs...) where {F,TT}
    sig = Base.signature_type(F, TT)
    args = (:F, (:( args[$i] ) for i in 1:length(args))...)

    # filter out ghost arguments that shouldn't be passed
    predicate = dt -> isghosttype(dt) || Core.Compiler.isconstType(dt)
    to_pass = map(!predicate, sig.parameters)
    call_t =                  Type[x[1] for x in zip(sig.parameters,  to_pass) if x[2]]
    call_args = Union{Expr,Symbol}[x[1] for x in zip(args, to_pass)            if x[2]]

    # replace non-isbits arguments (they should be unused, or compilation would have failed)
    # alternatively, allow `launch` with non-isbits arguments.
    for (i,dt) in enumerate(call_t)
        if !isbitstype(dt)
            # Enable passing non-isbitstype on stack
            # TODO: find better way to identify types that actually can be passed
            call_t[i] = Ptr{Any}
            call_args[i] = :C_NULL
        end
    end

    # finalize types
    call_tt = Base.to_tuple_type(call_t)
    @show call_tt

    quote
        Base.@_inline_meta

        vecall(kernel, $call_tt, $(call_args...); call_kwargs...)
    end
end

isghosttype(dt) = !ismutable(dt) && sizeof(dt) == 0

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
    params = VECompilerParams(device, global_hooks)
    job = CompilerJob(target, source, params)
    GPUCompiler.cached_compilation(cache, job, vefunction_compile, vefunction_link)::DeviceKernel{f,tt}
end

const vefunction_cache = Dict{UInt,Dict{UInt,Any}}()

function vefunction_compile(@nospecialize(job::CompilerJob))
    # compile
    method_instance, mi_meta = GPUCompiler.emit_julia(job)
    ir, ir_meta = GPUCompiler.emit_llvm(job, method_instance)
    kernel = ir_meta.entry
    #@show ir

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
    mod = VEModule(obj)
    fun = VEFunction(mod, entry)
    kernel = DeviceKernel{job.source.f,job.source.tt}(mod, fun)

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
(kernel::DeviceKernel)(args...; kwargs...) = call(kernel, args...; kwargs...)

@inline function vecall(kernel::DeviceKernel, tt, args...; kwargs...)
    VEDA.vecall(kernel.fun, tt, args...; kwargs...,)
end

@inline function vesync(; kwargs...)
    VEDA.vesync(; kwargs...)
end
