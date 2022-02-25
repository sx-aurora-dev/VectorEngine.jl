
export @synchronize

"""
    @synchronize ex

Run expression `ex` and synchronize the VE afterwards.

See also: [`synchronize`](@ref).
"""
macro synchronize(ex)
    quote
        local ret = $(esc(ex))
        VectorEngine.synchronize()
        ret
    end
end
