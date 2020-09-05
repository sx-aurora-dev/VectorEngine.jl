using Clang

function wrap_component(include, name)
    HEADERS = [joinpath(include, header) for header in readdir(include)
               if (startswith(header, name) && endswith(header, ".h"))]

    wc = init(; headers = HEADERS,
                output_file = joinpath(@__DIR__, "lib$(name).jl"),
                common_file = joinpath(@__DIR__, "lib$(name)_common.jl"),
                clang_includes = vcat(include, CLANG_INCLUDE),
                clang_args = ["-I", include],
                header_wrapped = (root, current)->root == current,
                header_library = x->"lib$(name)",
                clang_diagnostics = true,
                )
    run(wc)
end

wrap_component("/usr/local/ve/veda/include", "veda")
wrap_component("/usr/local/ve/veda/include", "vera")
