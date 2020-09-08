struct VECompilerParams <: AbstractCompilerParams end

const VECompilerJob = CompilerJob{VECompilerTarget, VECompilerParams}

GPUCompiler.runtime_module(::VECompilerJob) = VectorEngine

GPUCompiler.isintrinsic(job::VECompilerJob, fn::String) =
    invoke(GPUCompiler.isintrinsic,
           Tuple{CompilerJob{VECompilerTarget}, typeof(fn)},
           job, fn) ||
    true
