joltphysics_port :: () -> Port_Spec {
    return .{
        name = "joltphysics",
        upstream_url = "https://github.com/jrouwe/JoltPhysics.git",
        upstream_commit = "82b24442917ba8d9ced3582c2f2d8a49f4c969f6",
        upstream_label = "upstream/joltphysics",
        license_file = "LICENSE",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{
            enabled = true,
            source_directory = "Build",
            cache_variables = string.[
                "CMAKE_DISABLE_PRECOMPILE_HEADERS=ON",
                "TARGET_UNIT_TESTS=OFF",
                "TARGET_HELLO_WORLD=OFF",
                "TARGET_PERFORMANCE_TEST=OFF",
                "TARGET_SAMPLES=OFF",
                "TARGET_VIEWER=OFF",
            ],
        },
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "JPH",
            cmake_targets = string.["Jolt"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/joltphysics.git",
        supported_target = "linux-x64",
    };
}
