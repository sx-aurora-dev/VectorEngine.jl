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
USE_BINARYBUILDER_LLVM=0                                                                       │ create mode 100644 src/spirv.jl
LLVM_VER=svn                                                                                   │ delete mode 100644 test/Project.toml
LLVM_ASSERTIONS=1                                                                              │ create mode 100644 test/definitions/gcn.jl
LLVM_GIT_VER=hpce/develop                                                                      │ create mode 100644 test/definitions/ptx.jl
LLVM_GIT_URL=https://github.com/sx-aurora-dev/llvm-project                                     │ create mode 100644 test/definitions/spirv.jl
override LLVM_TARGETS=host;NVPTX;AMDGPU;VE
```

