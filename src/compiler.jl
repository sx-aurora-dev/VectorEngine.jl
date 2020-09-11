struct VECompilerParams <: AbstractCompilerParams end

const VECompilerJob = CompilerJob{VECompilerTarget, VECompilerParams}

GPUCompiler.runtime_module(::VECompilerJob) = VectorEngine

GPUCompiler.isintrinsic(job::VECompilerJob, fn::String) =
    invoke(GPUCompiler.isintrinsic,
           Tuple{CompilerJob{VECompilerTarget}, typeof(fn)},
           job, fn) ||
    true

# For now, completely disable the check for isbitstype arguments
# TODO: find a better way to identify arguments that can be passed on stack
function GPUCompiler.check_invocation(job::VECompilerJob, entry::LLVM.Function)
    return
end
