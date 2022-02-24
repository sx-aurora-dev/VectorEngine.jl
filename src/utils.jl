
export @sync

"""
    @sync ex

Run expression `ex` and synchronize the VE afterwards.

See also: [`synchronize`](@ref).
"""
macro sync(ex)
    quote
        local ret = $(esc(ex))
        VectorEngine.synchronize()
        ret
    end
end
