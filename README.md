# VectorEngine.jl

A first version of Julia enabled for the NEC SX-Aurora TSUBASA Vector Engine (VE).

It builds on a pre-release of julia-1.8 with additional patches and requires
modified versions of GPUCompiler.jl and LLVM.jl.

The LLVM compiler used is a branch of https://github.com/sx-aurora-dev/llvm-project
which was patched with a few Julia specific things. It is a pre-14.0.0 version, therefore
the patches in LLVM.jl, which (for julia-1.8) relies on LLVM 13.0.0.

LLVM-VE uses the RegionVectorizer (RV) for vectorization and has LoopVectorizer disabled.


## Features

Support for offloading kernels to the VE device eg. by using the `@veda` macro.

Using device side VEArrays.

Guided vectorization with the `@vectorize` macro.


## Limitations

Many.
Only rudimentary runtime on device side.


## Building

The build process is a bit rough and needs a few manual interventions. Should get smoother
once nearing the latest GPUCompiler version and julia-1.9, which requires LLVM-14.0.0.

Start with cloning the VectorEngine.jl project:
```
git clone git@github.com:sx-aurora-dev/VectorEngine.jl.git
cd VectorEngine.jl
```

Now clone the matching Julia branch inside the VectorEngine.jl directory. The location is,
of course, a matter of taste, I prefer to keep them together while developing.
```
git clone -b ef/ve-llvm14-release-1.8 git@github.com:efocht/julia.git
mkdir builds
cd julia
make O=`pwd`/../builds/julia-ve configure
cd ..
```


Create a `Make.user` file in the build directory:
```
cat <<EOF >builds/julia-ve/Make.user
USE_BINARYBUILDER_LLVM=0
FORCE_ASSERTIONS=1
LLVM_ASSERTIONS=1
#override JULIA_BUILD_MODE=debug
LLVM_DEBUG=2
DEPS_GIT=llvm
override LLVM_VER = 14.0.0
override LLVM_BRANCH=hpce/release_2.2.0_julia
override LLVM_SHA1=hpce/release_2.2.0_julia
override LLVM_GIT_URL=https://github.com/sx-aurora-dev/llvm-project
#override LLVM_TARGETS=host;WebAssembly;NVPTX;AMDGPU;BPF;VE
override LLVM_TARGETS=host;VE
EOF
```
Only the architecture targets `host` (x86_64) and `VE` are enabled because the others were
stripped from the llvm-ve repository. This will change once we can use the upstream (mainline)
LLVM. VE is an official architecture there, but the upstream VE part still lacks some pieces of
vectorization support.

Now build julia-ve:
```
cd builds/julia-ve
make -j 12
```


### Prepare GPUCompiler.jl and LLVM.jl

Since this is work in progress, I check out these packages locally, such that I can tweak them,
if needed. Certainly these steps can be shortened, but I'm documenting what I use and works for me.

Clone the LLVM.jl and GPUCompiler.jl packages. We need a certain branch for this when doing
`pkg> develop`, and cloning with "develop" does not support specifying a branch.
```
mkdir dev
cd dev
git clone -b ef/ve-llvm14-rebase-v4.9.1 https://github.com/efocht/LLVM.jl.git LLVM
git clone -b ef/ve-rebase-v0.14.1 https://github.com/efocht/GPUCompiler.jl.git GPUCompiler
cd ..
```

I had to remove and then add the explicitly checked out repositories:
```
builds/julia-ve/usr/bin/julia --project=.

# press ] to enter package mode
pkg> rm GPUCompiler
pkg> rm LLVM

pkg> dev --local JLLWrappers
pkg> dev dev/LLVM
pkg> dev dev/GPUCompiler
pkg> add Preferences
pkg> Ctrl-d
```
The package Preferences is added in order to support loading the LocalPreferences.toml which we
create in the next step.

Rebuild libLLVMExtra-14.so with assertion support. Julia will continue complaining about it, though,
because it always complains if assertions are enabled, but doesn't actually check for them.
```
cd dev/LLVM
../../builds/julia-ve/usr/bin/julia --project=deps
# press ] to enter package mode
pkg> add Scratch
pkg> Ctrl-d

# rebuild the library with "our" LLVM
env LLVM_DIR=../../builds/julia-ve/usr \
  ../../builds/julia-ve/usr/bin/julia --project=deps deps/build_local.jl ../../builds/julia-ve/usr/lib/cmake/llvm
```

Now copy the LocalPreferences.toml file into the VectorEngine.jl/ directory.
```
cp LocalPreferences.toml ../..
cd ../..
```

## Run tests
```
builds/julia-ve/usr/bin/julia --project=. test/runtests.jl
```

The output should end with something like:
```
Test Summary: | Pass  Total     Time
VectorEngine  |  103    103  1m10.8s
```
