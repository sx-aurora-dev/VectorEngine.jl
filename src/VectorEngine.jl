module VectorEngine
    using GPUCompiler
    using LLVM
    using LLVM.Interop

    include("veda/VEDA.jl")
    using .VEDA

    # Device and Memory management

    # Device sources must load _before_ the compiler infrastructure
    # because of generated functions.
    include(joinpath("device", "runtime.jl"))
    include(joinpath("device", "strings.jl"))

    # Compiler infrastructure
    include("compiler.jl")
    include("execution.jl")
    include("reflection.jl")

    # High-level functionality    
end # module
