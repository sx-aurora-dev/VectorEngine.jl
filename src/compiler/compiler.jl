using .GPUCompiler: classify_arguments, BITS_REF, BITS_VALUE

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

function GPUCompiler.process_entry!(@nospecialize(job::CompilerJob), mod::LLVM.Module,
                                    entry::LLVM.Function)
    ctx = context(mod)

    if haskey(ENV, "JULIA_VE_ARGS") && ENV["JULIA_VE_ARGS"] == "1"
        if job.source.kernel
            args = classify_arguments(job, eltype(llvmtype(entry)))
            for arg in args
                @debug "arg : $arg"
            end
        end
    end

    return entry
end
