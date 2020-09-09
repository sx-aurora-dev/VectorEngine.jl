## GPU runtime library

# reset the runtime cache from global scope, so that any change triggers recompilation
GPUCompiler.reset_runtime()

function signal_exception()
    return
end

function report_exception(ex)
    @veprintf("""
        ERROR: a %s was thrown during kernel execution.
        Run Julia on debug level 2 for device stack traces.
        """, ex)
    return
end

function report_oom(sz)
    @veprintf("ERROR: Out of dynamic VE memory (trying to allocate %i bytes)\n", sz)
    return
end

function report_exception_name(ex)
    @veprintf("""
        ERROR: a %s was thrown during kernel execution.
        Stacktrace:
        """, ex)
    return
end

function report_exception_frame(idx, func, file, line)
    @veprintf(" [%i] %s at %s:%i\n", idx, func, file, line)
    return
end