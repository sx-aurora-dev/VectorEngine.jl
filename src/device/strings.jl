export @static_string

macro static_string(str)
    quote
        $_static_string(Val(Symbol($str)))
    end
end

@generated function _static_string(::Val{Str}) where Str   
    JuliaContext() do ctx
        T_pint8 = LLVM.PointerType(LLVM.Int8Type(ctx))

        # create functions
        param_types = LLVMType[]
        llvm_f, _ = create_function(T_pint8, param_types)
        mod = LLVM.parent(llvm_f)

        # generate IR
        Builder(ctx) do builder
            entry = BasicBlock(llvm_f, "entry", ctx)
            position!(builder, entry)

            str = globalstring_ptr!(builder, string(Str))
            ret!(builder, str)
        end

        call_function(llvm_f, Ptr{Int8}, Tuple{})
    end
end
