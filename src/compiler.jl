struct VECompilerParams <: AbstractCompilerParams end

const VECompilerJob = CompilerJob{VECompilerTarget, VECompilerParams}

# GPUCompiler.runtime_module(::VECompilerJob) = VEDeviceLib
