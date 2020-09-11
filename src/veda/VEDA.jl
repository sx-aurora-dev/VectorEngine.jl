module VEDA
    include("api.jl")

    export VEModule, VEFunction, VEContext

    # Hardcoded linker path: from binutils-ve
    const nld_path = "/opt/nec/ve/bin/nld"

    # TODO: Find these at build time.

    mutable struct VEContext
        handle::API.VEDAcontext

        function VEContext(dev)
            r_handle = Ref{API.VEDAcontext}()
            API.vedaDevicePrimaryCtxRetain(r_handle, dev)
            ctx = new(r_handle[])
            finalizer(ctx) do ctx
                API.vedaDevicePrimaryCtxRelease(ctx.handle)
            end
        end
    end

    mutable struct VEModule
        handle::API.VEDAmodule

        function VEModule(vso::String)
            r_handle = Ref{API.VEDAmodule}()
            API.vedaModuleLoad(r_handle, vso)
            mod = new(r_handle[])
            finalizer(mod) do mod
                API.vedaModuleUnload(mod.handle)
            end
            return mod
        end
    end

    function VEModule(obj::Base.CodeUnits{UInt8, String})
        vso = mktemp() do path_o, io_o
            write(io_o, obj)
            flush(io_o)
            vso = path_o*".vso"
            run(`$nld_path -shared -o $vso $path_o`)
            vso
        end
        mod = VEModule(vso)
        rm(vso)
        mod
    end

    mutable struct VEFunction
        handle::API.VEDAfunction
        mod::VEModule

        function VEFunction(mod, fname)
            r_handle = Ref{API.VEDAfunction}()
            API.vedaModuleGetFunction(r_handle, mod.handle, fname)
            new(r_handle[], mod)
        end
    end

    include("execution.jl")

    const pctx = Ref{VEContext}()

    ## VEDA device library
    const libcache = Base.WeakKeyDict{VEContext, VEModule}()

    function __init__()
        isempty(API.libveda) && return
        # limiting to one core for now, as we're not using OpenMP
        ENV["VE_OMP_NUM_THREADS"] = 1
        # TODO: Do a lazy init
        API.vedaInit(0)
        ctx = VEContext(0)
        pctx[] = ctx
        API.vedaCtxSetCurrent(ctx.handle)
        atexit(API.vedaExit)
    end
end # module
