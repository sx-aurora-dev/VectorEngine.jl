# Device type and auxiliary functions

#using .API: VEDAdevice, VEDAdevice_attribute

export
    VEDevice, current_device, has_device, deviceid, physical_deviceid, aveo_deviceid,
    name, totalmem, can_access_peer

"""
    VEDevice(ordinal::Integer)

Get a handle to a compute device.
"""
struct VEDevice
    handle::VEDAdevice

    function VEDevice(ordinal::Integer)
        device_ref = Ref{VEDAdevice}()
        vedaDeviceGet(device_ref, ordinal)
        new(device_ref[])
    end

    global function current_device()
        device_ref = Ref{VEDAdevice}()
        res = vedaCtxGetDevice(device_ref)
        res == VEDA_ERROR_INVALID_CONTEXT && throw(UndefRefError())
        res != VEDA_SUCCESS && throw_api_error(res)
        return _VEDevice(device_ref[])
    end

    # for outer constructors
    global _VEDevice(handle::VEDAdevice) = new(handle)

end


"""
    deviceid(dev::VEDevice)

Returns the ordinal ID of a VEDevice.
"""
function deviceid(dev::VEDevice)
    return dev.handle
end

"""
    physical_deviceid(dev::VEDevice)

Returns the physical device ID of a VEDevice.
"""
function physical_deviceid(dev::VEDevice)
    phys_id = Ref{Int32}()
    vedaDeviceGetPhysicalId(phys_id, dev)
    return phys_id[]
end

"""
    aveo_deviceid(dev::VEDevice)

Returns the AVEO device ID of a VEDevice.
"""
function aveo_deviceid(dev::VEDevice)
    aveo_id = Ref{Int32}()
    vedaDeviceGetAVEOId(aveo_id, dev)
    return aveo_id[]
end

"""
    current_device()

Returns the current device.

!!! warning

    This is a low-level API, returning the current device as known to the CUDA driver.
    For most users, it is recommended to use the [`device`](@ref) method instead.
"""
current_device()

"""
    has_device()

Returns whether there is an active device.
"""
function has_device()
    device_ref = Ref{VEDAdevice}()
    res = vedaCtxGetDevice(device_ref)
    if res == VEDA_SUCCESS
        return true
    elseif res == VEDA_ERROR_INVALID_CONTEXT
        return false
    else
        throw_api_error(res)
    end
end

Base.convert(::Type{VEDAdevice}, dev::VEDevice) = dev.handle

function Base.show(io::IO, ::MIME"text/plain", dev::VEDevice)
    print(io, "VEDevice($(dev.handle)): ")
    print(io, "physical_id=$(physical_deviceid(dev)) ")
    print(io, "aveo_id=$(aveo_deviceid(dev)) ")
    print(io, "$(name(dev))")
end

"""
    name(dev::VEDevice)

Returns an identifier string for the device.
"""
function name(dev::VEDevice)
    buflen = 256
    buf = Vector{Cchar}(undef, buflen)
    vedaDeviceGetName(pointer(buf), buflen, dev)
    buf[end] = 0
    return unsafe_string(pointer(buf))
end

"""
    totalmem(dev::VEDevice)

Returns the total amount of memory (in bytes) on the device.
"""
function totalmem(dev::VEDevice)
    mem_ref = Ref{Csize_t}()
    vedaDeviceTotalMem_v2(mem_ref, dev)
    return mem_ref[]
end

# TODO: in principle this is true, but quick transfers are not yet
#       in AVEO.
function can_access_peer(dev::VEDevice, peer::VEDevice)
    return false
end


## device iteration

export devices, ndevices

struct DeviceIterator end

"""
    devices()

Get an iterator for the compute devices.
"""
devices() = DeviceIterator()

Base.eltype(::DeviceIterator) = VEDevice

function Base.iterate(iter::DeviceIterator, i=1)
    i >= length(iter) + 1 ? nothing : (VEDevice(i-1), i+1)
end

Base.length(::DeviceIterator) = ndevices()

Base.IteratorSize(::DeviceIterator) = Base.HasLength()

function Base.show(io::IO, ::MIME"text/plain", iter::DeviceIterator)
    print(io, "VEDA.DeviceIterator() for $(length(iter)) devices:\n")
    if !isempty(iter)
        for dev in iter
            print(io, "$(deviceid(dev)). ")
            print(io, "physical_id=$(physical_deviceid(dev)) ")
            print(io, "aveo_id=$(aveo_deviceid(dev)) ")
            print(io, "$(name(dev))\n")
        end
    end
end

function ndevices()
    count_ref = Ref{Cint}()
    vedaDeviceGetCount(count_ref)
    return count_ref[]
end


## attributes

export attribute

"""
    attribute(dev::VEDevice, code)

Returns information about the device.
"""
function attribute(dev::VEDevice, code::VEDAdevice_attribute)
    value_ref = Ref{Cint}()
    vedaDeviceGetAttribute(value_ref, code, dev)
    return value_ref[]
end

@enum_without_prefix VEDAdevice_attribute VEDA_DEVICE_ATTRIBUTE_

