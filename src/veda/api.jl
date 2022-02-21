module API
using CEnum
using Libdl

# TODO: This is quite simplistic, better create a build of VEDA through Yggdrasil
const libveda = Libdl.find_library("libveda.so.0", ["/usr/local/ve/veda/lib64/"])
if isempty(libveda)
    @warn "Could not find libveda, VectorEngine.jl will not function"
end

# TODO: figure out why Clang.jl missed these
const __VEDAcontext = Cvoid
const __VEDAmodule = Cvoid
const veoargs = Cvoid
const VEDAhost_function = Ptr{Cvoid}

include(joinpath(@__DIR__, "..", "..", "gen", "libveda_common.jl"))
include(joinpath(@__DIR__, "..", "..", "gen", "libveda.jl"))
end
