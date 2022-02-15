module VectorEngine
    using GPUCompiler
    using LLVM
    using LLVM.Interop

    import Core: LLVMPtr

    include("veda/VEDA.jl")
    using .VEDA

    # Device and Memory management
    include("pointer.jl")
    include("stream.jl")
    include("memory.jl")

    # Device sources must load _before_ the compiler infrastructure
    # because of generated functions.
    include(joinpath("device", "tools.jl"))
    include(joinpath("device", "memory.jl"))
    include(joinpath("device", "output.jl"))
    include(joinpath("device", "runtime.jl"))
    include(joinpath("device", "llvm.jl"))
    include(joinpath("device", "strings.jl"))

    # Compiler infrastructure
    include("compiler.jl")
    include("execution.jl")
    include("reflection.jl")

    # High-level functionality
end # module
