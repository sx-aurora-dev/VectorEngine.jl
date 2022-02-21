using Test
using LinearAlgebra
import Adapt

@testset "constructors" begin
  xs = VEArray{Int}(undef, 2, 3)
  @test collect(VEArray([1 2; 3 4])) == [1 2; 3 4]
  @test testf(vec, rand(5,3))
  @test Base.elsize(xs) == sizeof(Int)
  @test VEArray{Int, 2}(xs) === xs

  @test_throws ArgumentError Base.unsafe_convert(Ptr{Int}, xs)
  @test_throws ArgumentError Base.unsafe_convert(Ptr{Float32}, xs)

  @test collect(VectorEngine.zeros(2, 2)) == zeros(2, 2)
  @test collect(VectorEngine.ones(2, 2)) == ones(2, 2)

  @test collect(VectorEngine.fill(0, 2, 2)) == zeros(2, 2)
  @test collect(VectorEngine.fill(1, 2, 2)) == ones(2, 2)
end

@testset "adapt" begin
  A = rand(Float32, 3, 3)
  dA = VEArray(A)
  @test Adapt.adapt(Array, dA) == A
  @test Adapt.adapt(VEArray, A) isa VEArray
  @test Array(Adapt.adapt(VEArray, A)) == A
end

@testset "reshape" begin
  A = [1 2 3 4
       5 6 7 8]
  gA = reshape(VEArray(A),1,8)
  _A = reshape(A,1,8)
  _gA = Array(gA)
  @test all(_A .== _gA)
  A = [1,2,3,4]
  gA = reshape(VEArray(A),4)
end

@testset "fill(::SubArray)" begin
  xs = VectorEngine.zeros(3)
  fill!(view(xs, 2:2), 1)
  @test Array(xs) == [0,1,0]
end
