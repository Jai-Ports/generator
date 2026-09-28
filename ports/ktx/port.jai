ktx_port :: () -> Port_Spec {
    return .{
        name = "ktx",
        upstream_url = "https://github.com/KhronosGroup/KTX-Software.git",
        upstream_commit = "90967979cbb7e9401ee2401ff997f30b4b7507d6",
        upstream_label = "upstream/ktx",
        license_file = "LICENSE.md",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true, build_targets = string.[]},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "ktx",
            cmake_targets = string.["ktx", "basisu_encoder", "dfdutils", "astcenc-avx2-static"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/ktx.git",
        supported_target = "linux-x64",
    };
}
