shaderc_port :: () -> Port_Spec {
    return .{
        name = "shaderc",
        upstream_url = "https://github.com/google/shaderc.git",
        upstream_commit = "a8abeb0b8a9d4b11e3d59ca9f4550b8213e733ab",
        upstream_label = "upstream/shaderc",
        license_file = "LICENSE",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        dependencies = Port_Dependency_Spec.[
            .{name="shaderc-abseil-cpp", upstream_url="https://github.com/abseil/abseil-cpp.git", upstream_commit="dbf88f932096c7f7714356e919f04749eb87c3e9", upstream_label="upstream/shaderc-abseil-cpp", license_file="LICENSE"},
            .{name="shaderc-effcee", upstream_url="https://github.com/google/effcee.git", upstream_commit="f8e8a164822d4f65e757bff66bc00e1567959aa0", upstream_label="upstream/shaderc-effcee", license_file="LICENSE"},
            .{name="shaderc-googletest", upstream_url="https://github.com/google/googletest.git", upstream_commit="52eb8108c5bdec04579160ae17225d66034bd723", upstream_label="upstream/shaderc-googletest", license_file="LICENSE"},
            .{name="shaderc-glslang", upstream_url="https://github.com/KhronosGroup/glslang.git", upstream_commit="e1b562a8bed273a02f30b59b66a5d499793cede5", upstream_label="upstream/shaderc-glslang", license_file="LICENSE.txt"},
            .{name="shaderc-re2", upstream_url="https://github.com/google/re2.git", upstream_commit="972a15cedd008d846f1a39b2e88ce48d7f166cbd", upstream_label="upstream/shaderc-re2", license_file="LICENSE"},
            .{name="shaderc-spirv-headers", upstream_url="https://github.com/KhronosGroup/SPIRV-Headers.git", upstream_commit="04fd3caa1e8267e4d95c806cad901181728e1006", upstream_label="upstream/shaderc-spirv-headers", license_file="LICENSE"},
            .{name="shaderc-spirv-tools", upstream_url="https://github.com/KhronosGroup/SPIRV-Tools.git", upstream_commit="ef96ed763b43b59b33b31b362f09a02b729fa1c9", upstream_label="upstream/shaderc-spirv-tools", license_file="LICENSE"},
        ],
        cmake = .{
            enabled = true,
            source_cache_variables = Port_CMake_Source_Cache_Spec.[
                .{key="SHADERC_ABSL_DIR", source="@shaderc-abseil-cpp"},
                .{key="SHADERC_EFFCEE_DIR", source="@shaderc-effcee"},
                .{key="SHADERC_GOOGLE_TEST_DIR", source="@shaderc-googletest"},
                .{key="SHADERC_GLSLANG_DIR", source="@shaderc-glslang"},
                .{key="SHADERC_RE2_DIR", source="@shaderc-re2"},
                .{key="SHADERC_SPIRV_HEADERS_DIR", source="@shaderc-spirv-headers"},
                .{key="SHADERC_SPIRV_TOOLS_DIR", source="@shaderc-spirv-tools"},
            ],
            build_targets = string.["core_tables", "extinst_tables", "third_party/spirv-tools/build-version.inc"],
        },
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "shaderc",
            cmake_targets = string.["shaderc", "shaderc_util", "glslang", "SPIRV", "SPIRV-Tools-static", "SPIRV-Tools-opt"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/shaderc.git",
        supported_target = "linux-x64",
    };
}
