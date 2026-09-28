spirv_cross_port :: () -> Port_Spec {
    return .{
        name = "spirv_cross",
        upstream_url = "https://github.com/KhronosGroup/SPIRV-Cross.git",
        upstream_commit = "aa217aeb6c9f0ace7a0ab233b28807edf45eb165",
        upstream_label = "upstream/spirv_cross",
        license_file = "LICENSE",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true, cache_variables = string.[]},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "spvc",
            cmake_targets = string.["spirv-cross-core", "spirv-cross-glsl", "spirv-cross-cpp", "spirv-cross-reflect", "spirv-cross-msl", "spirv-cross-hlsl", "spirv-cross-util", "spirv-cross-c"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/spirv_cross.git",
        supported_target = "linux-x64",
    };
}
