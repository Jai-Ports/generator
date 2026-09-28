basis_universal_port :: () -> Port_Spec {
    return .{
        name = "basis_universal",
        upstream_url = "https://github.com/BinomialLLC/basis_universal.git",
        upstream_commit = "99f52d63aa6799cbdaecfe977111dc5ec3b31d47",
        upstream_label = "upstream/basis_universal",
        license_file = "LICENSE",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true, cache_variables = string.[]},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "basisu",
            cmake_targets = string.["basisu_encoder"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/basis_universal.git",
        supported_target = "linux-x64",
    };
}
