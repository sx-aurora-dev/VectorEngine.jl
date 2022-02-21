module VectorEngine

using GPUArrays
using Adapt

using GPUCompiler
using LLVM
using LLVM.Interop

import Core: LLVMPtr

include("pointer.jl")

include("veda/VEDA.jl")
using .VEDA

# Device and Memory management
include("stream.jl")
include("memory.jl")

# Device sources must load _before_ the compiler infrastructure
# because of generated functions.
include(joinpath("device", "tools.jl"))
include(joinpath("device", "pointer.jl"))
include(joinpath("device", "output.jl"))
include(joinpath("device", "memory.jl"))
include(joinpath("device", "array.jl"))
include(joinpath("device", "runtime.jl"))
include(joinpath("device", "llvm.jl"))
include(joinpath("device", "strings.jl"))

# Compiler infrastructure
include("compiler.jl")
include("execution.jl")
include("reflection.jl")

# array essentials
include("array.jl")

# High-level functionality
include("random.jl")
include("utils.jl")
end # module
