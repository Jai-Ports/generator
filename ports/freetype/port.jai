freetype_port :: () -> Port_Spec {
    return .{
        name = "freetype",
        upstream_url = "https://github.com/freetype/freetype.git",
        upstream_commit = "d333439633039de426f943f28a2926c7f97b5ae5",
        upstream_label = "upstream/freetype",
        license_file = "LICENSE.TXT",
        language = .C,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true, cache_variables = string.[]},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "freetype",
            cmake_targets = string.["freetype"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/freetype.git",
        supported_target = "linux-x64",
    };
}
