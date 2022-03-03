# Tools for implementing device functionality

export @wrap

# which Julia types map to a given LLVM type
const llvmtypes = Dict{Type,Symbol}(
    Nothing => :void,
    Bool    => :i1,
    Int8    => :i8,
    Int16   => :i16,
    Int32   => :i32,
    Int64   => :i64,
    UInt8   => :i8,
    UInt16  => :i16,
    UInt32  => :i32,
    UInt64  => :i64,
    Float32 => :float,
    Float64 => :double,
)

# which LLVM types map to a given Julia type
const jltypes = Dict{Symbol,Type}(
    :void   => Nothing,
    :i1     => Bool,
    :i8     => Int8,
    :i16    => Int16,
    :i32    => Int32,
    :i64    => Int64,
    :float  => Float32,
    :double => Float64
)

# which Julia types map to a given ROC lib type
const fntypes = Dict{Type,Symbol}(
    Nothing => :void,
    Bool    => :bool,
    Int8    => :i8,
    Int16   => :i16,
    Int32   => :i32,
    Int64   => :i64,
    UInt8   => :u8,
    UInt16  => :u16,
    UInt32  => :u32,
    UInt64  => :u64,
    Float16 => :f16,
    Float32 => :f32,
    Float64 => :f64
)

# Decode an expression of the form:
#
#    function(arg::arg_type, arg::arg_type, ... arg::arg_type)::return_type
#
# Returns a tuple containing the function name, a vector of argument, a vector of argument
# types and the return type (all in symbolic form).
function decode_call(e)
    @assert e.head == :(::)

    # decode the return type expression: single symbol (the LLVM type), or a tuple of 2
    # symbols (the LLVM and corresponding Julia type)
    retspec = e.args[2]
    if isa(retspec, Symbol)
        rettype = retspec
    else
        @assert retspec.head == :tuple
        @assert length(retspec.args) == 2
        rettype = (retspec.args[1], retspec.args[2])
    end

    call = e.args[1]
    @assert call.head == :call

    fn = Symbol(call.args[1])
    args = Symbol[arg.args[1] for arg in call.args[2:end]]
    argtypes = Symbol[arg.args[2] for arg in call.args[2:end]]

    return fn, args, argtypes, rettype
end

# Generate a `llvmcall` statement calling an intrinsic specified as follows:
#
#     intrinsic(arg::arg_type, arg::arg_type, ... arg::arg_type)::return_type [attr]
#
# The argument types should be valid LLVM type identifiers (eg. i32, float, double).
# Conversions to the corresponding Julia type are automatically generated; make sure the
# actual arguments are of the same type to make these conversions no-ops. The optional
# argument `attr` indicates which LLVM function attributes (such as `readnone` or `nounwind`)
# to add to the intrinsic declaration.

# For example, the following call:
#     `@wrap __some_intrinsic(x::float, y::double)::float`
#
# will yield the following `llvmcall`:
# ```
#     Base.llvmcall(("declare float @__somme__intr(float, double)",
#                    "%3 = call float @__somme__intr(float %0, double %1)
#                     ret float %3"),
#                   Float32, Tuple{Float32,Float64},
#                   convert(Float32,x), convert(Float64,y))
# ```
macro wrap(call, attrs="")
    intrinsic, args, argtypes, rettype = decode_call(call)

    # decide on intrinsic return type
    if isa(rettype, Symbol)
        # only LLVM return type specified, match against known LLVM/Julia type combinations
        llvm_ret_typ = rettype
        julia_ret_typ = jltypes[rettype]
    else
        # both specified (for when there is a mismatch, eg. i32 -> UInt32)
        llvm_ret_typ = rettype[1]
        julia_ret_typ = rettype[2]
    end

    llvm_args = String["%$i" for i in 0:length(argtypes)]
    if llvm_ret_typ == :void
        llvm_ret_asgn = ""
        llvm_ret = "void"
    else
        llvm_ret_var = "%$(length(argtypes)+1)"
        llvm_ret_asgn = "$llvm_ret_var = "
        llvm_ret = "$llvm_ret_typ $llvm_ret_var"
    end
    llvm_declargs = join(argtypes, ", ")
    llvm_defargs = join(("$t $arg" for (t,arg) in zip(argtypes, llvm_args)), ", ")

    julia_argtypes = (jltypes[t] for t in argtypes)
    julia_args = (:(convert($argtype, $(esc(arg)))) for (arg, argtype) in zip(args, julia_argtypes))

    dest = ("""declare $llvm_ret_typ @$intrinsic($llvm_declargs)""",
            """$llvm_ret_asgn call $llvm_ret_typ @$intrinsic($llvm_defargs)
                ret $llvm_ret""")

    return quote
        Base.llvmcall($dest, $julia_ret_typ, Tuple{$(julia_argtypes...)}, $(julia_args...))
    end
end

# calculate the size of an LLVM type
llvmsize(::LLVM.LLVMHalf) = sizeof(Float16)
llvmsize(::LLVM.LLVMFloat) = sizeof(Float32)
llvmsize(::LLVM.LLVMDouble) = sizeof(Float64)
llvmsize(::LLVM.IntegerType) = Context() do ctx
    div(Int(intwidth(GenericValue(LLVM.Int128Type(ctx), -1))), 8)
end
llvmsize(ty::LLVM.ArrayType) = length(ty)*llvmsize(eltype(ty))
llvmsize(ty::LLVM.StructType) = ispacked(ty) ? sum(llvmsize(elem) for elem in elements(ty)) : 8*length(elements(ty)) # FIXME: Properly determine non-packed sizing
llvmsize(ty::LLVM.PointerType) = div(Sys.WORD_SIZE, 8)
llvmsize(ty::LLVM.VectorType) = size(ty)
llvmsize(ty) = error("Unknown size for type: $ty, typeof: $(typeof(ty))")

@generated function string_length(ex::Union{Ptr,LLVMPtr})
    Context() do ctx
        T_ex = convert(LLVMType, ex; ctx)
        T_ex_ptr = LLVM.PointerType(T_ex)
        T_i8_ptr = LLVM.PointerType(LLVM.Int8Type(ctx))
        T_i64 = LLVM.Int64Type(ctx)
        llvm_f, _ = create_function(T_i64, [T_ex])
        mod = LLVM.parent(llvm_f)
        Builder(ctx) do builder
            entry = BasicBlock(llvm_f, "entry"; ctx)
            check = BasicBlock(llvm_f, "check"; ctx)
            done = BasicBlock(llvm_f, "done"; ctx)

            position!(builder, entry)
            init_offset = ConstantInt(0; ctx)
            input_ptr = if T_ex isa LLVM.PointerType
                parameters(llvm_f)[1]
            else
                inttoptr!(builder, parameters(llvm_f)[1], T_ex_ptr)
            end
            if LLVM.addrspace(llvmtype(input_ptr)) != LLVM.addrspace(T_ex_ptr)
                input_ptr = addrspacecast!(builder, input_ptr, T_ex_ptr)
            end
            input_ptr = bitcast!(builder, input_ptr, T_i8_ptr)
            br!(builder, check)

            position!(builder, check)
            offset = phi!(builder, T_i64)
            next_offset = add!(builder, offset, ConstantInt(1; ctx))
            append!(LLVM.incoming(offset), [(init_offset, entry), (next_offset, check)])
            ptr = gep!(builder, input_ptr, [offset])
            value = load!(builder, ptr)
            cond = icmp!(builder, LLVM.API.LLVMIntEQ, value, ConstantInt(0x0; ctx))
            br!(builder, cond, done, check)

            position!(builder, done)
            ret!(builder, offset)
        end
        call_function(llvm_f, Csize_t, Tuple{ex}, :ex)
    end
end

