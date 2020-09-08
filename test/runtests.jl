using VectorEngine
using Test

@testset "VEDA" begin
    @testset "Memory Operations" begin
        include("memory.jl")
    end
    @testset "Pointer Operations" begin
        include("pointer.jl")
    end
end
