using VectorEngine

#
# pass a char string
#

function pass_string(r::Ptr{UInt8})
      @veshow(r)
      @veprintf("[VE string]: %s\n", r)
      return
end

veps = VectorEngine.vefunction(pass_string, Tuple{Ptr{UInt8}})
veps("1234567890abcdefghij")

VectorEngine.VEDA.API.vedaCtxSynchronize()
