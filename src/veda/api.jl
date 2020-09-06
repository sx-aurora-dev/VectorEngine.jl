module API
    using CEnum

    # TODO: figure out why Clang.jl missed these
    const __VEDAcontext = Cvoid
    const __VEDAmodule = Cvoid
    const veoargs = Cvoid
    const VEDAhost_function = Ptr{Cvoid}

    include(joinpath(@__DIR__, "..", "..", "gen", "libveda_common.jl"))
    include(joinpath(@__DIR__, "..", "..", "gen", "libveda.jl"))
end