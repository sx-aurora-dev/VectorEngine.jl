module VectorEngine
    using GPUCompiler
    include("veda/VEDA.jl")

    include("compiler.jl")
    include("reflection.jl")
end # module
