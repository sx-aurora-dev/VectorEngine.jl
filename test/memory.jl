let
    a,b = Mem.info()
    # NOTE: actually testing this is pretty fragile on CI
    #=@test a == =# VectorEngine.available_memory()
    #=@test b == =# VectorEngine.total_memory()
end

# dummy data
T = UInt32
N = 5
data = rand(T, N)
nb = sizeof(data)

# buffers are untyped, so we use a convenience function to get a typed pointer
# we prefer to return a device pointer (for managed buffers) to maximize VectorEngine coverage
typed_pointer(buf::Mem.Device, T) = convert(VEPtr{T}, buf)
typed_pointer(buf::Mem.Host, T)   = convert(Ptr{T},   buf)

# allocations and copies
for srcTy in [Mem.Device, Mem.Host],
    dstTy in [Mem.Device, Mem.Host]

    local dummy = Mem.alloc(srcTy, 0)
    Mem.free(dummy)

    src = Mem.alloc(srcTy, nb)
    unsafe_copyto!(typed_pointer(src, T), pointer(data), N)

    dst = Mem.alloc(dstTy, nb)
    unsafe_copyto!(typed_pointer(dst, T), typed_pointer(src, T), N)

    ref = Array{T}(undef, N)
    unsafe_copyto!(pointer(ref), typed_pointer(dst, T), N)

    @test data == ref

    if isa(src, Mem.Device)
        Mem.set!(typed_pointer(src, T), zero(T), N)
    end

    Mem.free(src)
    Mem.free(dst)
end

# asynchronous operations
let
    src = Mem.alloc(Mem.Device, nb)

    @test_throws ArgumentError unsafe_copyto!(typed_pointer(src, T), pointer(data), N; async=true)
    unsafe_copyto!(typed_pointer(src, T), pointer(data), N; async=true, stream=VEDefaultStream())

    Mem.set!(typed_pointer(src, T), zero(T), N; async=true, stream=VEDefaultStream())

    Mem.free(src)
end
