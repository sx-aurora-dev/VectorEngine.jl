using Clang

# Only wrap VEDA for now since VERA requires C++
INCLUDE_PATH = "/usr/local/ve/veda/include"

HEADERS = [
    "veda.h",
    "veda_types.h",
    "veda_enums.h",
]
HEADERS = map(h->joinpath(INCLUDE_PATH, h), HEADERS)
NAME = "veda"

wc = init(; headers = HEADERS,
            output_file = joinpath(@__DIR__, "lib$(NAME).jl"),
            common_file = joinpath(@__DIR__, "lib$(NAME)_common.jl"),
            clang_includes = vcat(INCLUDE_PATH, CLANG_INCLUDE),
            clang_args = ["-I", INCLUDE_PATH],
            header_wrapped = (root, current)->  current == root,
            header_library = x->"lib$(NAME)",
            clang_diagnostics = true,
            )
run(wc)

