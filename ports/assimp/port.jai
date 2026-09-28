assimp_port :: () -> Port_Spec {
    return .{
        name = "assimp",
        upstream_url = "https://github.com/assimp/assimp.git",
        upstream_commit = "a4eff9f89585c590d7b43daf5065f7bdf398bbc6",
        upstream_label = "upstream/assimp",
        license_file = "LICENSE",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{
            enabled = true,
            cache_variables = string.[
                "ASSIMP_BUILD_TESTS=OFF",
                "ASSIMP_BUILD_ASSIMP_TOOLS=OFF",
                "CMAKE_DISABLE_PRECOMPILE_HEADERS=ON",
            ],
        },
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "ai",
            cmake_targets = string.["assimp"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/assimp.git",
        supported_target = "linux-x64",
    };
}
