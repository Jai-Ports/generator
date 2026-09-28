msdf_atlas_gen_port :: () -> Port_Spec {
    return .{
        name = "msdf-atlas-gen",
        upstream_url = "https://github.com/Chlumsky/msdf-atlas-gen.git",
        upstream_commit = "6148900d59423059bafde2f51a0cb303184404bd",
        upstream_label = "upstream/msdf-atlas-gen",
        license_file = "LICENSE.txt",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        submodules = Port_Submodule_Spec.[
            .{
                name = "msdfgen",
                path = "msdfgen",
                upstream_url = "https://github.com/Chlumsky/msdfgen",
                upstream_commit = "84f183a6c8137c42abc5728b29ed274bab3edeb0",
                license_file = "LICENSE.txt",
            },
            .{
                name = "artery-font-format",
                path = "artery-font-format",
                upstream_url = "https://github.com/Chlumsky/artery-font-format",
                upstream_commit = "af79386abe0857fe1c30be97eec760dbd84022c5",
                license_file = "LICENSE.txt",
            },
        ],
        cmake = .{
            enabled = true,
            // Use installed dependency packages. Skia remains required; its
            // absence must stop configuration instead of reducing features.
            cache_variables = string.[
                "MSDF_ATLAS_BUILD_STANDALONE=OFF",
                "MSDF_ATLAS_USE_VCPKG=OFF",
                "CMAKE_DISABLE_PRECOMPILE_HEADERS=ON",
            ],
        },
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "msdf_atlas",
            cmake_targets = string.["msdf-atlas-gen", "msdfgen-core", "msdfgen-ext"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/msdf-atlas-gen.git",
        supported_target = "linux-x64",
    };
}
