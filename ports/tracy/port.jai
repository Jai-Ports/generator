tracy_port :: () -> Port_Spec {
    return .{
        name = "tracy",
        upstream_url = "https://github.com/wolfpld/tracy.git",
        upstream_commit = "81c5005509bf8f9d3cad90eb8155e24b8597a1dd",
        upstream_label = "upstream/tracy",
        license_file = "LICENSE",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true, cache_variables = string.["TRACY_ENABLE=ON"]},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "tracy",
            cmake_targets = string.["TracyClient"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/tracy.git",
        supported_target = "linux-x64",
    };
}
