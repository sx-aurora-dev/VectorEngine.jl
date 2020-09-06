## GPU runtime library

# reset the runtime cache from global scope, so that any change triggers recompilation
GPUCompiler.reset_runtime()

function signal_exception()
    return
end

function report_exception(ex)
    return
end

function report_oom(sz)
    return
end

function report_exception_name(ex)
    return
end

function report_exception_frame(idx, func, file, line)
    return
end