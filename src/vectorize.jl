export @vectorize

# Error thrown from ill-formed uses of @vec
struct VectorizeError <: Exception
    msg::String
end

julia_ivdep() = Symbol("julia.ivdep")
vectorize_enable(flag) = (Symbol("llvm.loop.vectorize.enable"), convert(Bool, flag))
vectorize_width(n) = (Symbol("llvm.loop.vectorize.width"), convert(Int, n))

function loopinfo(name, expr, nodes...)
    if expr.head != :for
        error("Syntax error: pragma $name needs a for loop")
    end
    push!(expr.args[2].args, Expr(:loopinfo, nodes...))
    return expr
end

"""
    @vectorize [ivdep] [length=512] for ...
        ...
    end

Instrument "for" loop IR with metadata controling its vectorization. Without further
options the llvm.loop.vectorize.enable(true) marker is set. The optional "ivdep" adds
metadata to mark memory accesses inside the loop as independent of each other. The
"length" option can set a different vectorization width than the default (256 on VE).
Loops using only 32 bit entities might benefit of packed vectorization by setting
`length=512`.
"""
macro vectorize(expr...)
    loop = expr[end]
    args = expr[1:end-1]
    N = 0
    ivdep = false
    for arg in args
        if arg.head == :(=) && arg.args[1] == :length
            if arg.args[2] isa Integer
                N = arg.args[2]
            else
                throw(VectorizeError("@vectorize length value must be an integer!"))
            end
        elseif arg === :ivdep
            ivdep = true
        else
            throw(VectorizeError("Only 'ivdep' and 'length=...' are "*
                "valid as the first argument to @vectorize"))
        end
    end
    nodes = (vectorize_enable(true),)
    if N > 0
        nodes = (vectorize_width(N), nodes...)
    end
    if ivdep
        nodes = (julia_ivdep(), nodes...)
    end
    return esc(loopinfo("@vectorize", loop, nodes...))
end
