using VectorEngine
using GPUCompiler
using LinearAlgebra
using LLVM, LLVM.Interop
using Test

using Random
Random.seed!(1)

include("setup.jl")

@testset "VectorEngine" begin
    @testset "Memory Operations" begin
        include("memory.jl")
    end
    @testset "Pointer Operations" begin
        include("pointer.jl")
    end
    @testset "Arrays" begin
        include("array.jl")
    end
    @testset "Execution" begin
        include("execution.jl")
    end
    @testset "Examples" begin
        include("examples.jl")
    end

    
    #@testset "Device Tests" begin
    #    include("device/globals.jl")
    #end
end
