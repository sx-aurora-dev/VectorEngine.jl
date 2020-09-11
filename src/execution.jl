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

"""
    vefunction(f, tt=Tuple{}; kwargs...)

Low-level interface to compile a function invocation, returning
a callable kernel object.
- `name`: override the name that the kernel will have in the generated code
The output of this function is automatically cached, i.e. you can simply call `vefunction`
in a hot path without degrading performance. New code will be generated automatically, when
when function changes, or when different types or keyword arguments are provided.
"""
function vefunction(f::Core.Function, tt::Type=Tuple{}; name=nothing, kernel=true, kwargs...)
    source = FunctionSpec(f, tt, kernel, name)
    GPUCompiler.cached_compilation(_vefunction, source; kwargs...)::HostKernel{f,tt}
end

# actual compilation
function _vefunction(source::FunctionSpec; kwargs...)
    # compile to GCN
    target = VECompilerTarget()
    params = VECompilerParams()
    job = CompilerJob(target, source, params)
    obj, kernel_fn, undefined_fns, undefined_gbls = GPUCompiler.compile(:obj, job)

    # create executable and kernel
    obj = codeunits(obj)
    mod = VEModule(obj)
    fun = VEFunction(mod, kernel_fn)
    kernel = HostKernel{source.f,source.tt}(mod, fun)

    return kernel
end

# https://github.com/JuliaLang/julia/issues/14919
(kernel::HostKernel)(args...; kwargs...) = call(kernel, args...; kwargs...)

@inline function vecall(kernel::HostKernel, tt, args...; kwargs...)
    VEDA.vecall(kernel.fun, tt, args...; kwargs...,)
end
