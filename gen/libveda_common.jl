# Automatically generated using Clang.jl


const VEDAdevice = Cint
const VEDAdeviceptr = Cint
const veo_args = Cvoid
const VEDAfunction = Cint
const VEDAcontext = Ptr{__VEDAcontext}
const VEDAmodule = Ptr{__VEDAmodule}
const VEDAstream = Cint
const VEDAargs = Ptr{veo_args}

# Skipping Typedef: CXType_FunctionProto uint64_t

const VEDAstream_callback = Ptr{Cvoid}

@cenum VEDAresult_enum::UInt32 begin
    VEDA_SUCCESS = 0
    VEDA_ERROR_ALREADY_INITIALIZED = 1
    VEDA_ERROR_CANNOT_CREATE_CONTEXT = 2
    VEDA_ERROR_CANNOT_CREATE_DEVICE = 3
    VEDA_ERROR_CANNOT_CREATE_STREAM = 4
    VEDA_ERROR_CANNOT_POP_CONTEXT = 5
    VEDA_ERROR_FUNCTION_NOT_FOUND = 6
    VEDA_ERROR_INITIALIZING_DEVICE = 7
    VEDA_ERROR_INVALID_ARGS = 8
    VEDA_ERROR_INVALID_CONTEXT = 9
    VEDA_ERROR_INVALID_COREIDX = 10
    VEDA_ERROR_INVALID_DEVICE = 11
    VEDA_ERROR_INVALID_MODULE = 12
    VEDA_ERROR_INVALID_STREAM = 13
    VEDA_ERROR_INVALID_VALUE = 14
    VEDA_ERROR_MODULE_NOT_FOUND = 15
    VEDA_ERROR_NOT_IMPLEMENTED = 16
    VEDA_ERROR_NOT_INITIALIZED = 17
    VEDA_ERROR_NO_CONTEXT = 18
    VEDA_ERROR_NO_DEVICES_FOUND = 19
    VEDA_ERROR_NO_SENSOR_FILE = 20
    VEDA_ERROR_OUT_OF_MEMORY = 21
    VEDA_ERROR_OFFSETTED_VPTR_NOT_ALLOWED = 22
    VEDA_ERROR_UNABLE_TO_DETECT_DEVICES = 23
    VEDA_ERROR_UNKNOWN_CONTEXT = 24
    VEDA_ERROR_UNKNOWN_DEVICE = 25
    VEDA_ERROR_UNKNOWN_KERNEL = 26
    VEDA_ERROR_UNKNOWN_MODULE = 27
    VEDA_ERROR_UNKNOWN_STREAM = 28
    VEDA_ERROR_UNKNOWN_VPTR = 29
    VEDA_ERROR_UNKNOWN_PPTR = 30
    VEDA_ERROR_VEDA_LD_LIBRARY_PATH_NOT_DEFINED = 31
    VEDA_ERROR_VEO_COMMAND_ERROR = 32
    VEDA_ERROR_VEO_COMMAND_EXCEPTION = 33
    VEDA_ERROR_VEO_COMMAND_UNFINISHED = 34
    VEDA_ERROR_VEO_COMMAND_UNKNOWN_ERROR = 35
    VEDA_ERROR_VEO_STATE_BLOCKED = 36
    VEDA_ERROR_VEO_STATE_RUNNING = 37
    VEDA_ERROR_VEO_STATE_SYSCALL = 38
    VEDA_ERROR_VEO_STATE_UNKNOWN = 39
    VEDA_ERROR_VPTR_ALREADY_ALLOCATED = 40
    VEDA_ERROR_SHUTTING_DOWN = 41
    VEDA_ERROR_UNKNOWN = 42
end

@cenum VEDAdevice_attribute_enum::UInt32 begin
    VEDA_DEVICE_ATTRIBUTE_CLOCK_RATE = 0
    VEDA_DEVICE_ATTRIBUTE_CLOCK_BASE = 1
    VEDA_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT = 2
    VEDA_DEVICE_ATTRIBUTE_MEMORY_CLOCK_RATE = 3
    VEDA_DEVICE_ATTRIBUTE_L1D_CACHE_SIZE = 4
    VEDA_DEVICE_ATTRIBUTE_L1I_CACHE_SIZE = 5
    VEDA_DEVICE_ATTRIBUTE_L2_CACHE_SIZE = 6
    VEDA_DEVICE_ATTRIBUTE_ABI_VERSION = 7
    VEDA_DEVICE_ATTRIBUTE_SINGLE_TO_DOUBLE_PRECISION_PERF_RATIO = 8
    VEDA_DEVICE_ATTRIBUTE_FIREWARE_VERSION = 9
end

@cenum VEDAargs_intent_enum::UInt32 begin
    VEDA_ARGS_INTENT_IN = 0
    VEDA_ARGS_INTENT_INOUT = 1
    VEDA_ARGS_INTENT_OUT = 2
end

@cenum VEDAcontext_mode_enum::UInt32 begin
    VEDA_CONTEXT_MODE_OMP = 0
    VEDA_CONTEXT_MODE_SCALAR = 1
end


const VEDAresult = VEDAresult_enum
const VEDAdevice_attribute = VEDAdevice_attribute_enum
const VEDAargs_intent = VEDAargs_intent_enum
const VEDAcontext_mode = VEDAcontext_mode_enum
