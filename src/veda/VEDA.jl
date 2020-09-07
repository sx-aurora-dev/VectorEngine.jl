module VEDA
    include("api.jl")

    export VEModule, VEFunction, VEContext

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

    const pctx = Ref{VEContext}()

    function __init__()
        # TODO: Do a lazy init
        API.vedaInit(0)
        pctx[] = VEContext(0)
        API.vedaCtxSetCurrent(pctx[].handle)
        atexit(API.vedaExit)
    end

    mutable struct VEModule
        handle::API.VEDAmodule

        function VEModule(obj)
            vso = mktemp() do path_o, io_o
                write(io_o, obj)
                flush(io_o)
                vso = path_o*".vso"
                # Hardcoded linker path: from binutils-ve
                run(`/opt/nec/ve/bin/nld -shared -o $vso $path_o`)
                vso
            end

            r_handle = Ref{API.VEDAmodule}()
            API.vedaModuleLoad(r_handle, vso)
            mod = new(r_handle[])
            finalizer(mod) do mod
                API.vedaModuleUnload(mod.handle)
                rm(vso)
            end
            return mod
        end
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
end # module
