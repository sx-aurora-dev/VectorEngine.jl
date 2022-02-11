# VectorEngine.jl

## Building a compatible Julia

```sh
git clone -b ef/ve-llvm14 git@github.com:efocht/julia.git
mkdir builds
cd julia
make O=`pwd`/../builds/julia-ve configure
cd ..
```

Create a file `builds/julia-ve/Make.user` containing

```
USE_BINARYBUILDER_LLVM=0
FORCE_ASSERTIONS=1
LLVM_ASSERTIONS=1
#override JULIA_BUILD_MODE=debug
LLVM_DEBUG=2
DEPS_GIT=llvm
override LLVM_VER = 14.0.0
override LLVM_BRANCH=hpce/julia-merge-20220128
override LLVM_SHA1=hpce/julia-merge-20220128
override LLVM_GIT_URL=https://github.com/sx-aurora-dev/llvm-project
override LLVM_TARGETS=host;WebAssembly;NVPTX;AMDGPU;BPF;VE
```

Now run 
```
make -j 12
```
