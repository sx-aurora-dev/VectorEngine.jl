struct VECompilerParams <: AbstractCompilerParams
    device::Int32
    global_hooks::NamedTuple
end

VECompilerJob = CompilerJob{VECompilerTarget, VECompilerParams}

GPUCompiler.runtime_module(::VECompilerJob) = VectorEngine

# filter out functions from device libs
GPUCompiler.isintrinsic(job::VECompilerJob, fn::String) =
    invoke(GPUCompiler.isintrinsic,
           Tuple{CompilerJob{VECompilerTarget}, typeof(fn)},
           job, fn) ||
    true
    #startswith(fn, "ve")

# For now, completely disable the check for isbitstype arguments
# TODO: find a better way to identify arguments that can be passed on stack
function GPUCompiler.check_invocation(job::VECompilerJob, entry::LLVM.Function)
    return
end

