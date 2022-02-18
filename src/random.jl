using Random

Random.rand!(A::VEWrappedArray) = Random.rand!(GPUArrays.default_rng(VEArray), A)
Random.randn!(A::VEWrappedArray) = Random.randn!(GPUArrays.default_rng(VEArray), A)

