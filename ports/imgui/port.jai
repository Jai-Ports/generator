imgui_port :: () -> Port_Spec {
    return .{
        name = "imgui",

        upstream_url = "https://github.com/ocornut/imgui.git",
        upstream_commit = "6d910d5487d11ca567b61c7824b0c78c569d62f0",
        upstream_label = "upstream/imgui",
        license_file = "LICENSE.txt",

        language = .CPP,
        standard = "c++11",
        include_directories = string.[],
        compiler_flags = string.[
            "-fno-exceptions",
            "-fno-rtti",
            "-fwrapv",
            "-ffp-contract=off",
        ],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "imgui",
            source_files = string.[
                "imgui.cpp",
                "imgui_draw.cpp",
                "imgui_tables.cpp",
                "imgui_widgets.cpp",
            ],
            defines = string.[],
            generated_entry = "cpp_transpiler_program.jai",
        }],

        output_url = "git@github.com:Jai-Ports/imgui.git",
        supported_target = "linux-x64",
    };
}
