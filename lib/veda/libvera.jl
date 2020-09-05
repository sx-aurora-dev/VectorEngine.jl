# Julia wrapper for header: vera.h
# Automatically generated using Clang.jl


function veraInit()
    ccall((:veraInit, libvera), Cint, ())
end

function veraDeviceReset()
    ccall((:veraDeviceReset, libvera), Cint, ())
end

function veraGetDeviceProperties()
    ccall((:veraGetDeviceProperties, libvera), Cint, ())
end

function veraMalloc3D()
    ccall((:veraMalloc3D, libvera), Cint, ())
end

function veraMemcpy()
    ccall((:veraMemcpy, libvera), Cint, ())
end

function veraMemcpy2D()
    ccall((:veraMemcpy2D, libvera), Cint, ())
end

function veraMemcpy2DAsync()
    ccall((:veraMemcpy2DAsync, libvera), Cint, ())
end

function veraMemcpyAsync()
    ccall((:veraMemcpyAsync, libvera), Cint, ())
end

function veraMemset2D()
    ccall((:veraMemset2D, libvera), Cint, ())
end

function veraMemset2DAsync()
    ccall((:veraMemset2DAsync, libvera), Cint, ())
end

function veraMemset3D()
    ccall((:veraMemset3D, libvera), Cint, ())
end

function veraMemset3DAsync()
    ccall((:veraMemset3DAsync, libvera), Cint, ())
end

function veraPointerGetAttributes()
    ccall((:veraPointerGetAttributes, libvera), Cint, ())
end

function veraSetDevice()
    ccall((:veraSetDevice, libvera), Cint, ())
end

function veraSetValidDevices()
    ccall((:veraSetValidDevices, libvera), Cint, ())
end

function veraStreamAddCallback()
    ccall((:veraStreamAddCallback, libvera), Cint, ())
end

function veraGetErrorName(error)
    ccall((:veraGetErrorName, libvera), Cstring, (Cint,), error)
end

function veraGetErrorString(error)
    ccall((:veraGetErrorString, libvera), Cstring, (Cint,), error)
end

function veraDeviceGetAttribute()
    ccall((:veraDeviceGetAttribute, libvera), Cint, ())
end

function veraDeviceGetPower()
    ccall((:veraDeviceGetPower, libvera), Cint, ())
end

function veraDeviceGetTemp()
    ccall((:veraDeviceGetTemp, libvera), Cint, ())
end

function veraDeviceSynchronize()
    ccall((:veraDeviceSynchronize, libvera), Cint, ())
end

function veraDriverGetVersion()
    ccall((:veraDriverGetVersion, libvera), Cint, ())
end

function veraFree()
    ccall((:veraFree, libvera), Cint, ())
end

function veraFreeAsync()
    ccall((:veraFreeAsync, libvera), Cint, ())
end

function veraFreeHost()
    ccall((:veraFreeHost, libvera), Cint, ())
end

function veraGetDevice()
    ccall((:veraGetDevice, libvera), Cint, ())
end

function veraGetDeviceCount()
    ccall((:veraGetDeviceCount, libvera), Cint, ())
end

function veraHostAlloc()
    ccall((:veraHostAlloc, libvera), Cint, ())
end

function veraLaunchHostFunc()
    ccall((:veraLaunchHostFunc, libvera), Cint, ())
end

function veraMalloc()
    ccall((:veraMalloc, libvera), Cint, ())
end

function veraMallocAsync()
    ccall((:veraMallocAsync, libvera), Cint, ())
end

function veraMallocHost()
    ccall((:veraMallocHost, libvera), Cint, ())
end

function veraMallocPitch()
    ccall((:veraMallocPitch, libvera), Cint, ())
end

function veraMemGetInfo()
    ccall((:veraMemGetInfo, libvera), Cint, ())
end

function veraMemset()
    ccall((:veraMemset, libvera), Cint, ())
end

function veraMemsetAsync()
    ccall((:veraMemsetAsync, libvera), Cint, ())
end

function veraModuleGetFunction()
    ccall((:veraModuleGetFunction, libvera), Cint, ())
end

function veraModuleUnload()
    ccall((:veraModuleUnload, libvera), Cint, ())
end

function veraModuleLoad()
    ccall((:veraModuleLoad, libvera), Cint, ())
end

function veraRuntimeGetVersion()
    ccall((:veraRuntimeGetVersion, libvera), Cint, ())
end

function veraStreamCnt()
    ccall((:veraStreamCnt, libvera), Cint, ())
end

function veraStreamQuery()
    ccall((:veraStreamQuery, libvera), Cint, ())
end

function veraStreamSynchronize()
    ccall((:veraStreamSynchronize, libvera), Cint, ())
end

function make_veraExtent()
    ccall((:make_veraExtent, libvera), Cint, ())
end

function make_veraPitchedPtr()
    ccall((:make_veraPitchedPtr, libvera), Cint, ())
end
