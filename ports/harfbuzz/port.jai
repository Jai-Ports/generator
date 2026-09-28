harfbuzz_port :: () -> Port_Spec {
    return .{
        name = "harfbuzz",
        upstream_url = "https://github.com/harfbuzz/harfbuzz.git",
        upstream_commit = "b3bab62307017934dd7f532c52a696fefb12b3ad",
        upstream_label = "upstream/harfbuzz",
        license_file = "COPYING",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true, cache_variables = string.[]},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "hb",
            cmake_targets = string.["harfbuzz", "harfbuzz-subset", "harfbuzz-raster", "harfbuzz-vector", "harfbuzz-gpu"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/harfbuzz.git",
        supported_target = "linux-x64",
    };
}
