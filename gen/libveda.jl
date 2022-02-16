# Julia wrapper for header: veda.h
# Automatically generated using Clang.jl


function vedaArgsCreate(args)
    ccall((:vedaArgsCreate, libveda), VEDAresult, (Ptr{VEDAargs},), args)
end

function vedaArgsDestroy(args)
    ccall((:vedaArgsDestroy, libveda), VEDAresult, (VEDAargs,), args)
end

function vedaArgsSetF32(args, idx, value)
    ccall((:vedaArgsSetF32, libveda), VEDAresult, (VEDAargs, Cint, Cfloat), args, idx, value)
end

function vedaArgsSetF64(args, idx, value)
    ccall((:vedaArgsSetF64, libveda), VEDAresult, (VEDAargs, Cint, Cdouble), args, idx, value)
end

function vedaArgsSetI16(args, idx, value)
    ccall((:vedaArgsSetI16, libveda), VEDAresult, (VEDAargs, Cint, Int16), args, idx, value)
end

function vedaArgsSetI32(args, idx, value)
    ccall((:vedaArgsSetI32, libveda), VEDAresult, (VEDAargs, Cint, Int32), args, idx, value)
end

function vedaArgsSetI64(args, idx, value)
    ccall((:vedaArgsSetI64, libveda), VEDAresult, (VEDAargs, Cint, Int64), args, idx, value)
end

function vedaArgsSetI8(args, idx, value)
    ccall((:vedaArgsSetI8, libveda), VEDAresult, (VEDAargs, Cint, Int8), args, idx, value)
end

function vedaArgsSetPtr(args, idx, value)
    ccall((:vedaArgsSetPtr, libveda), VEDAresult, (VEDAargs, Cint, VEDAdeviceptr), args, idx, value)
end

function vedaArgsSetVPtr(args, idx, value)
    ccall((:vedaArgsSetVPtr, libveda), VEDAresult, (VEDAargs, Cint, VEDAdeviceptr), args, idx, value)
end

function vedaArgsSetHMEM(args, idx, value)
    ccall((:vedaArgsSetHMEM, libveda), VEDAresult, (VEDAargs, Cint, Ptr{Cvoid}), args, idx, value)
end

function vedaArgsSetStack(args, idx, ptr, intent, size)
    ccall((:vedaArgsSetStack, libveda), VEDAresult, (VEDAargs, Cint, Ptr{Cvoid}, VEDAargs_intent, Csize_t), args, idx, ptr, intent, size)
end

function vedaArgsSetU16(args, idx, value)
    ccall((:vedaArgsSetU16, libveda), VEDAresult, (VEDAargs, Cint, UInt16), args, idx, value)
end

function vedaArgsSetU32(args, idx, value)
    ccall((:vedaArgsSetU32, libveda), VEDAresult, (VEDAargs, Cint, UInt32), args, idx, value)
end

function vedaArgsSetU64(args, idx, value)
    ccall((:vedaArgsSetU64, libveda), VEDAresult, (VEDAargs, Cint, UInt64), args, idx, value)
end

function vedaArgsSetU8(args, idx, value)
    ccall((:vedaArgsSetU8, libveda), VEDAresult, (VEDAargs, Cint, UInt8), args, idx, value)
end

function vedaCtxCreate(pctx, mode, dev)
    ccall((:vedaCtxCreate, libveda), VEDAresult, (Ptr{VEDAcontext}, Cint, VEDAdevice), pctx, mode, dev)
end

function vedaCtxDestroy(ctx)
    ccall((:vedaCtxDestroy, libveda), VEDAresult, (VEDAcontext,), ctx)
end

function vedaCtxGet(ctx, device)
    ccall((:vedaCtxGet, libveda), VEDAresult, (Ptr{VEDAcontext}, VEDAdevice), ctx, device)
end

function vedaCtxGetApiVersion(ctx, version)
    ccall((:vedaCtxGetApiVersion, libveda), VEDAresult, (VEDAcontext, Ptr{UInt32}), ctx, version)
end

function vedaCtxGetCurrent(pctx)
    ccall((:vedaCtxGetCurrent, libveda), VEDAresult, (Ptr{VEDAcontext},), pctx)
end

function vedaCtxGetDevice(device)
    ccall((:vedaCtxGetDevice, libveda), VEDAresult, (Ptr{VEDAdevice},), device)
end

function vedaCtxPopCurrent(pctx)
    ccall((:vedaCtxPopCurrent, libveda), VEDAresult, (Ptr{VEDAcontext},), pctx)
end

function vedaCtxPushCurrent(ctx)
    ccall((:vedaCtxPushCurrent, libveda), VEDAresult, (VEDAcontext,), ctx)
end

function vedaCtxSetCurrent(ctx)
    ccall((:vedaCtxSetCurrent, libveda), VEDAresult, (VEDAcontext,), ctx)
end

function vedaCtxStreamCnt(cnt)
    ccall((:vedaCtxStreamCnt, libveda), VEDAresult, (Ptr{Cint},), cnt)
end

function vedaCtxSynchronize()
    ccall((:vedaCtxSynchronize, libveda), VEDAresult, ())
end

function vedaDeviceDistance(distance, devA, devB)
    ccall((:vedaDeviceDistance, libveda), VEDAresult, (Ptr{Cfloat}, VEDAdevice, VEDAdevice), distance, devA, devB)
end

function vedaDeviceGet(device, ordinal)
    ccall((:vedaDeviceGet, libveda), VEDAresult, (Ptr{VEDAdevice}, Cint), device, ordinal)
end

function vedaDeviceGetAVEOId(id, dev)
    ccall((:vedaDeviceGetAVEOId, libveda), VEDAresult, (Ptr{Cint}, VEDAdevice), id, dev)
end

function vedaDeviceGetAttribute(pi, attrib, dev)
    ccall((:vedaDeviceGetAttribute, libveda), VEDAresult, (Ptr{Cint}, VEDAdevice_attribute, VEDAdevice), pi, attrib, dev)
end

function vedaDeviceGetCount(count)
    ccall((:vedaDeviceGetCount, libveda), VEDAresult, (Ptr{Cint},), count)
end

function vedaDeviceGetCurrent(current, dev)
    ccall((:vedaDeviceGetCurrent, libveda), VEDAresult, (Ptr{Cfloat}, VEDAdevice), current, dev)
end

function vedaDeviceGetCurrentEdge(current, dev)
    ccall((:vedaDeviceGetCurrentEdge, libveda), VEDAresult, (Ptr{Cfloat}, VEDAdevice), current, dev)
end

function vedaDeviceGetNUMAId(id, dev)
    ccall((:vedaDeviceGetNUMAId, libveda), VEDAresult, (Ptr{Cint}, VEDAdevice), id, dev)
end

function vedaDeviceGetName(name, len, dev)
    ccall((:vedaDeviceGetName, libveda), VEDAresult, (Cstring, Cint, VEDAdevice), name, len, dev)
end

function vedaDeviceGetPhysicalId(id, dev)
    ccall((:vedaDeviceGetPhysicalId, libveda), VEDAresult, (Ptr{Cint}, VEDAdevice), id, dev)
end

function vedaDeviceGetPower(power, dev)
    ccall((:vedaDeviceGetPower, libveda), VEDAresult, (Ptr{Cfloat}, VEDAdevice), power, dev)
end

function vedaDeviceGetTemp(tempC, coreIdx, dev)
    ccall((:vedaDeviceGetTemp, libveda), VEDAresult, (Ptr{Cfloat}, Cint, VEDAdevice), tempC, coreIdx, dev)
end

function vedaDeviceGetVoltage(voltage, dev)
    ccall((:vedaDeviceGetVoltage, libveda), VEDAresult, (Ptr{Cfloat}, VEDAdevice), voltage, dev)
end

function vedaDeviceGetVoltageEdge(voltage, dev)
    ccall((:vedaDeviceGetVoltageEdge, libveda), VEDAresult, (Ptr{Cfloat}, VEDAdevice), voltage, dev)
end

function vedaDevicePrimaryCtxGetState(dev, flags, active)
    ccall((:vedaDevicePrimaryCtxGetState, libveda), VEDAresult, (VEDAdevice, Ptr{UInt32}, Ptr{Cint}), dev, flags, active)
end

function vedaDevicePrimaryCtxRelease(dev)
    ccall((:vedaDevicePrimaryCtxRelease, libveda), VEDAresult, (VEDAdevice,), dev)
end

function vedaDevicePrimaryCtxReset(dev)
    ccall((:vedaDevicePrimaryCtxReset, libveda), VEDAresult, (VEDAdevice,), dev)
end

function vedaDevicePrimaryCtxRetain(pctx, dev)
    ccall((:vedaDevicePrimaryCtxRetain, libveda), VEDAresult, (Ptr{VEDAcontext}, VEDAdevice), pctx, dev)
end

function vedaDevicePrimaryCtxSetFlags(dev, flags)
    ccall((:vedaDevicePrimaryCtxSetFlags, libveda), VEDAresult, (VEDAdevice, UInt32), dev, flags)
end

function vedaDeviceTotalMem(bytes, dev)
    ccall((:vedaDeviceTotalMem, libveda), VEDAresult, (Ptr{Csize_t}, VEDAdevice), bytes, dev)
end

function vedaDriverGetVersion(str)
    ccall((:vedaDriverGetVersion, libveda), VEDAresult, (Ptr{Cstring},), str)
end

function vedaExit()
    ccall((:vedaExit, libveda), VEDAresult, ())
end

function vedaGetErrorName(error, pStr)
    ccall((:vedaGetErrorName, libveda), VEDAresult, (VEDAresult, Ptr{Cstring}), error, pStr)
end

function vedaGetErrorString(error, pStr)
    ccall((:vedaGetErrorString, libveda), VEDAresult, (VEDAresult, Ptr{Cstring}), error, pStr)
end

function vedaGetVersion(str)
    ccall((:vedaGetVersion, libveda), VEDAresult, (Ptr{Cstring},), str)
end

function vedaInit(Flags)
    ccall((:vedaInit, libveda), VEDAresult, (UInt32,), Flags)
end

function vedaLaunchHostFunc(stream, fn, userData)
    ccall((:vedaLaunchHostFunc, libveda), VEDAresult, (VEDAstream, VEDAhost_function, Ptr{Cvoid}), stream, fn, userData)
end

function vedaLaunchHostFuncEx(stream, fn, userData, result)
    ccall((:vedaLaunchHostFuncEx, libveda), VEDAresult, (VEDAstream, VEDAhost_function, Ptr{Cvoid}, Ptr{UInt64}), stream, fn, userData, result)
end

function vedaLaunchKernel(f, stream, arg1)
    ccall((:vedaLaunchKernel, libveda), VEDAresult, (VEDAfunction, VEDAstream, VEDAargs), f, stream, arg1)
end

function vedaLaunchKernelEx(f, stream, arg1, destroyArgs, result)
    ccall((:vedaLaunchKernelEx, libveda), VEDAresult, (VEDAfunction, VEDAstream, VEDAargs, Cint, Ptr{UInt64}), f, stream, arg1, destroyArgs, result)
end

function vedaMemAlloc(ptr, size)
    ccall((:vedaMemAlloc, libveda), VEDAresult, (Ptr{VEDAdeviceptr}, Csize_t), ptr, size)
end

function vedaMemAllocAsync(ptr, size, stream)
    ccall((:vedaMemAllocAsync, libveda), VEDAresult, (Ptr{VEDAdeviceptr}, Csize_t, VEDAstream), ptr, size, stream)
end

function vedaMemAllocHost(pp, bytesiz)
    ccall((:vedaMemAllocHost, libveda), VEDAresult, (Ptr{Ptr{Cvoid}}, Csize_t), pp, bytesiz)
end

function vedaMemAllocPitch(ptr, pPitch, WidthInBytes, Height, ElementSizeByte)
    ccall((:vedaMemAllocPitch, libveda), VEDAresult, (Ptr{VEDAdeviceptr}, Ptr{Csize_t}, Csize_t, Csize_t, UInt32), ptr, pPitch, WidthInBytes, Height, ElementSizeByte)
end

function vedaMemAllocPitchAsync(ptr, pPitch, WidthInBytes, Height, ElementSizeByte, stream)
    ccall((:vedaMemAllocPitchAsync, libveda), VEDAresult, (Ptr{VEDAdeviceptr}, Ptr{Csize_t}, Csize_t, Csize_t, UInt32, VEDAstream), ptr, pPitch, WidthInBytes, Height, ElementSizeByte, stream)
end

function vedaMemFree(ptr)
    ccall((:vedaMemFree, libveda), VEDAresult, (VEDAdeviceptr,), ptr)
end

function vedaMemFreeAsync(ptr, stream)
    ccall((:vedaMemFreeAsync, libveda), VEDAresult, (VEDAdeviceptr, VEDAstream), ptr, stream)
end

function vedaMemFreeHost(ptr)
    ccall((:vedaMemFreeHost, libveda), VEDAresult, (Ptr{Cvoid},), ptr)
end

function vedaMemGetAddressRange(base, size, ptr)
    ccall((:vedaMemGetAddressRange, libveda), VEDAresult, (Ptr{VEDAdeviceptr}, Ptr{Csize_t}, VEDAdeviceptr), base, size, ptr)
end

function vedaMemGetDevice(dev, ptr)
    ccall((:vedaMemGetDevice, libveda), VEDAresult, (Ptr{VEDAdevice}, VEDAdeviceptr), dev, ptr)
end

function vedaMemGetInfo(free, total)
    ccall((:vedaMemGetInfo, libveda), VEDAresult, (Ptr{Csize_t}, Ptr{Csize_t}), free, total)
end

function vedaMemHMEM(ptr, vptr)
    ccall((:vedaMemHMEM, libveda), VEDAresult, (Ptr{Ptr{Cvoid}}, VEDAdeviceptr), ptr, vptr)
end

function vedaMemHMEMSize(ptr, size, vptr)
    ccall((:vedaMemHMEMSize, libveda), VEDAresult, (Ptr{Ptr{Cvoid}}, Ptr{Csize_t}, VEDAdeviceptr), ptr, size, vptr)
end

function vedaMemPtr(ptr, vptr)
    ccall((:vedaMemPtr, libveda), VEDAresult, (Ptr{Ptr{Cvoid}}, VEDAdeviceptr), ptr, vptr)
end

function vedaMemPtrSize(ptr, size, vptr)
    ccall((:vedaMemPtrSize, libveda), VEDAresult, (Ptr{Ptr{Cvoid}}, Ptr{Csize_t}, VEDAdeviceptr), ptr, size, vptr)
end

function vedaMemReport()
    ccall((:vedaMemReport, libveda), VEDAresult, ())
end

function vedaMemSize(size, ptr)
    ccall((:vedaMemSize, libveda), VEDAresult, (Ptr{Csize_t}, VEDAdeviceptr), size, ptr)
end

function vedaMemSwap(A, B)
    ccall((:vedaMemSwap, libveda), VEDAresult, (VEDAdeviceptr, VEDAdeviceptr), A, B)
end

function vedaMemSwapAsync(A, B, hStream)
    ccall((:vedaMemSwapAsync, libveda), VEDAresult, (VEDAdeviceptr, VEDAdeviceptr, VEDAstream), A, B, hStream)
end

function vedaMemcpy(dst, src, ByteCount)
    ccall((:vedaMemcpy, libveda), VEDAresult, (VEDAdeviceptr, VEDAdeviceptr, Csize_t), dst, src, ByteCount)
end

function vedaMemcpyAsync(dst, src, ByteCount, hStream)
    ccall((:vedaMemcpyAsync, libveda), VEDAresult, (VEDAdeviceptr, VEDAdeviceptr, Csize_t, VEDAstream), dst, src, ByteCount, hStream)
end

function vedaMemcpyDtoD(dstDevice, srcDevice, ByteCount)
    ccall((:vedaMemcpyDtoD, libveda), VEDAresult, (VEDAdeviceptr, VEDAdeviceptr, Csize_t), dstDevice, srcDevice, ByteCount)
end

function vedaMemcpyDtoDAsync(dstDevice, srcDevice, ByteCount, hStream)
    ccall((:vedaMemcpyDtoDAsync, libveda), VEDAresult, (VEDAdeviceptr, VEDAdeviceptr, Csize_t, VEDAstream), dstDevice, srcDevice, ByteCount, hStream)
end

function vedaMemcpyDtoH(dstHost, srcDevice, ByteCount)
    ccall((:vedaMemcpyDtoH, libveda), VEDAresult, (Ptr{Cvoid}, VEDAdeviceptr, Csize_t), dstHost, srcDevice, ByteCount)
end

function vedaMemcpyDtoHAsync(dstHost, srcDevice, ByteCount, hStream)
    ccall((:vedaMemcpyDtoHAsync, libveda), VEDAresult, (Ptr{Cvoid}, VEDAdeviceptr, Csize_t, VEDAstream), dstHost, srcDevice, ByteCount, hStream)
end

function vedaMemcpyHtoD(dstDevice, srcHost, ByteCount)
    ccall((:vedaMemcpyHtoD, libveda), VEDAresult, (VEDAdeviceptr, Ptr{Cvoid}, Csize_t), dstDevice, srcHost, ByteCount)
end

function vedaMemcpyHtoDAsync(dstDevice, srcHost, ByteCount, hStream)
    ccall((:vedaMemcpyHtoDAsync, libveda), VEDAresult, (VEDAdeviceptr, Ptr{Cvoid}, Csize_t, VEDAstream), dstDevice, srcHost, ByteCount, hStream)
end

function vedaMemsetD128(dstDevice, x, y, N)
    ccall((:vedaMemsetD128, libveda), VEDAresult, (VEDAdeviceptr, UInt64, UInt64, Csize_t), dstDevice, x, y, N)
end

function vedaMemsetD128Async(dstDevice, x, u, N, hStream)
    ccall((:vedaMemsetD128Async, libveda), VEDAresult, (VEDAdeviceptr, UInt64, UInt64, Csize_t, VEDAstream), dstDevice, x, u, N, hStream)
end

function vedaMemsetD16(dstDevice, us, N)
    ccall((:vedaMemsetD16, libveda), VEDAresult, (VEDAdeviceptr, UInt16, Csize_t), dstDevice, us, N)
end

function vedaMemsetD16Async(dstDevice, us, N, hStream)
    ccall((:vedaMemsetD16Async, libveda), VEDAresult, (VEDAdeviceptr, UInt16, Csize_t, VEDAstream), dstDevice, us, N, hStream)
end

function vedaMemsetD2D128(dstDevice, dstPitch, x, y, Width, Height)
    ccall((:vedaMemsetD2D128, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt64, UInt64, Csize_t, Csize_t), dstDevice, dstPitch, x, y, Width, Height)
end

function vedaMemsetD2D128Async(dstDevice, dstPitch, x, y, Width, Height, hStream)
    ccall((:vedaMemsetD2D128Async, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt64, UInt64, Csize_t, Csize_t, VEDAstream), dstDevice, dstPitch, x, y, Width, Height, hStream)
end

function vedaMemsetD2D16(dstDevice, dstPitch, us, Width, Height)
    ccall((:vedaMemsetD2D16, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt16, Csize_t, Csize_t), dstDevice, dstPitch, us, Width, Height)
end

function vedaMemsetD2D16Async(dstDevice, dstPitch, us, Width, Height, hStream)
    ccall((:vedaMemsetD2D16Async, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt16, Csize_t, Csize_t, VEDAstream), dstDevice, dstPitch, us, Width, Height, hStream)
end

function vedaMemsetD2D32(dstDevice, dstPitch, ui, Width, Height)
    ccall((:vedaMemsetD2D32, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt32, Csize_t, Csize_t), dstDevice, dstPitch, ui, Width, Height)
end

function vedaMemsetD2D32Async(dstDevice, dstPitch, ui, Width, Height, hStream)
    ccall((:vedaMemsetD2D32Async, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt32, Csize_t, Csize_t, VEDAstream), dstDevice, dstPitch, ui, Width, Height, hStream)
end

function vedaMemsetD2D64(dstDevice, dstPitch, ul, Width, Height)
    ccall((:vedaMemsetD2D64, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt64, Csize_t, Csize_t), dstDevice, dstPitch, ul, Width, Height)
end

function vedaMemsetD2D64Async(dstDevice, dstPitch, ul, Width, Height, hStream)
    ccall((:vedaMemsetD2D64Async, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt64, Csize_t, Csize_t, VEDAstream), dstDevice, dstPitch, ul, Width, Height, hStream)
end

function vedaMemsetD2D8(dstDevice, dstPitch, uc, Width, Height)
    ccall((:vedaMemsetD2D8, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt8, Csize_t, Csize_t), dstDevice, dstPitch, uc, Width, Height)
end

function vedaMemsetD2D8Async(dstDevice, dstPitch, uc, Width, Height, hStream)
    ccall((:vedaMemsetD2D8Async, libveda), VEDAresult, (VEDAdeviceptr, Csize_t, UInt8, Csize_t, Csize_t, VEDAstream), dstDevice, dstPitch, uc, Width, Height, hStream)
end

function vedaMemsetD32(dstDevice, ui, N)
    ccall((:vedaMemsetD32, libveda), VEDAresult, (VEDAdeviceptr, UInt32, Csize_t), dstDevice, ui, N)
end

function vedaMemsetD32Async(dstDevice, ui, N, hStream)
    ccall((:vedaMemsetD32Async, libveda), VEDAresult, (VEDAdeviceptr, UInt32, Csize_t, VEDAstream), dstDevice, ui, N, hStream)
end

function vedaMemsetD64(dstDevice, ui, N)
    ccall((:vedaMemsetD64, libveda), VEDAresult, (VEDAdeviceptr, UInt64, Csize_t), dstDevice, ui, N)
end

function vedaMemsetD64Async(dstDevice, ui, N, hStream)
    ccall((:vedaMemsetD64Async, libveda), VEDAresult, (VEDAdeviceptr, UInt64, Csize_t, VEDAstream), dstDevice, ui, N, hStream)
end

function vedaMemsetD8(dstDevice, uc, N)
    ccall((:vedaMemsetD8, libveda), VEDAresult, (VEDAdeviceptr, UInt8, Csize_t), dstDevice, uc, N)
end

function vedaMemsetD8Async(dstDevice, uc, N, hStream)
    ccall((:vedaMemsetD8Async, libveda), VEDAresult, (VEDAdeviceptr, UInt8, Csize_t, VEDAstream), dstDevice, uc, N, hStream)
end

function vedaModuleGetFunction(hfunc, hmod, name)
    ccall((:vedaModuleGetFunction, libveda), VEDAresult, (Ptr{VEDAfunction}, VEDAmodule, Cstring), hfunc, hmod, name)
end

function vedaModuleLoad(_module, fname)
    ccall((:vedaModuleLoad, libveda), VEDAresult, (Ptr{VEDAmodule}, Cstring), _module, fname)
end

function vedaModuleUnload(hmod)
    ccall((:vedaModuleUnload, libveda), VEDAresult, (VEDAmodule,), hmod)
end

function vedaStreamAddCallback(stream, callback, userData, flags)
    ccall((:vedaStreamAddCallback, libveda), VEDAresult, (VEDAstream, VEDAstream_callback, Ptr{Cvoid}, UInt32), stream, callback, userData, flags)
end

function vedaStreamGetFlags(hStream, flags)
    ccall((:vedaStreamGetFlags, libveda), VEDAresult, (VEDAstream, Ptr{UInt32}), hStream, flags)
end

function vedaStreamQuery(hStream)
    ccall((:vedaStreamQuery, libveda), VEDAresult, (VEDAstream,), hStream)
end

function vedaStreamSynchronize(hStream)
    ccall((:vedaStreamSynchronize, libveda), VEDAresult, (VEDAstream,), hStream)
end
# Julia wrapper for header: veda_types.h
# Automatically generated using Clang.jl

# Julia wrapper for header: veda_enums.h
# Automatically generated using Clang.jl

# Julia wrapper for header: veda_device.h
# Automatically generated using Clang.jl

# Julia wrapper for header: veda_device_omp.h
# Automatically generated using Clang.jl

# Julia wrapper for header: veda_ptr.h
# Automatically generated using Clang.jl

