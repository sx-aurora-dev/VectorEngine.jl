
export @sync

"""
    @sync ex

Run expression `ex` and synchronize the VE afterwards.

See also: [`vesync`](@ref).
"""
macro sync(ex)
    quote
        local ret = $(esc(ex))
        VectorEngine.vesync()
        ret
    end
end
