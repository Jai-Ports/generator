libjpeg_turbo_port :: () -> Port_Spec {
    return .{
        name = "libjpeg_turbo",
        upstream_url = "https://github.com/libjpeg-turbo/libjpeg-turbo.git",
        upstream_commit = "b33c60b439d58bc3564d0d32c1bb397fcfb77dc6",
        upstream_label = "upstream/libjpeg_turbo",
        license_file = "LICENSE.md",
        language = .C,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true, cache_variables = string.["WITH_SIMD=OFF", "ENABLE_SHARED=OFF", "WITH_SYSTEM_ZLIB=OFF", "WITH_SYSTEM_SPNG=OFF"]},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "libjpeg_turbo",
            cmake_targets = string.["turbojpeg-static", "spng-static", "zlib-static"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/libjpeg_turbo.git",
        supported_target = "linux-x64",
    };
}
