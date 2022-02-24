using VectorEngine, Test


@noinline function f(p)
    @veprintln(p[])
    p[] = 12
end

function pass(p)
    f(p)
    return
end

x = 10
VectorEngine.@sync @veda pass(Ref(x))
@show x

y = VERefValue(100)
VectorEngine.@sync @veda pass(y)
@show y

