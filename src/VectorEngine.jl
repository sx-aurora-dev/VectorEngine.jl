module VectorEngine
    using GPUCompiler
    include("veda/VEDA.jl")
    using .VEDA

    # Device and Memory management

    # Device sources must load _before_ the compiler infrastructure
    # because of generated functions.
    include(joinpath("device", "runtime.jl"))

    # Compiler infrastructure
    include("compiler.jl")
    include("execution.jl")
    include("reflection.jl")

    # High-level functionality    
end # module
