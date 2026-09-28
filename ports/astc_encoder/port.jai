astc_encoder_port :: () -> Port_Spec {
    return .{
        name = "astc_encoder",
        upstream_url = "https://github.com/ARM-software/astc-encoder.git",
        upstream_commit = "9fbec68053d507023bb30e2a449f900a915882b9",
        upstream_label = "upstream/astc_encoder",
        license_file = "LICENSE.txt",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true, cache_variables = string.[]},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "astcenc",
            cmake_targets = string.["astcenc-native-static", "astcenc-native-veneer1", "astcenc-native-veneer2"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/astc_encoder.git",
        supported_target = "linux-x64",
    };
}
