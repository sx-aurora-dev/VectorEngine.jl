export malloc, free

@inline function malloc(sz::Csize_t)::Ptr{Cvoid}
    ccall("extern malloc", llvmcall, Ptr{Cvoid}, (Csize_t,), sz)
end

@inline function free(ptr::Ptr{Cvoid})
    ccall("extern free", llvmcall, Cvoid, (Ptr{Cvoid},), ptr)
end
