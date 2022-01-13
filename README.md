# VectorEngine.jl

## Building a compatible Julia

```sh
git clone https://github.com/JuliaLang/julia
mkdir builds
cd julia
make O=`pwd`../builds/julia-ve configure
```

Create a file `builds/julia-ve/Make.user` containing

```
USE_BINARYBUILDER_LLVM=0
LLVM_VER=svn
LLVM_ASSERTIONS=1
LLVM_GIT_VER=hpce/develop
LLVM_GIT_URL=https://github.com/sx-aurora-dev/llvm-project
override LLVM_TARGETS=host;NVPTX;AMDGPU;VE
```

