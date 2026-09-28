imguizmo_port :: () -> Port_Spec {
    return .{
        name = "imguizmo",
        upstream_url = "https://github.com/CedricGuillemet/ImGuizmo.git",
        upstream_commit = "18cef5e031d8c6973d80284c67f60549fafd78c1",
        upstream_label = "upstream/imguizmo",
        license_file = "LICENSE",
        language = .CPP,
        standard = "c++11",
        include_directories = string.["src", "@imgui"],
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        dependencies = Port_Dependency_Spec.[.{
            name = "imgui",
            upstream_url = "https://github.com/ocornut/imgui.git",
            upstream_commit = "6d910d5487d11ca567b61c7824b0c78c569d62f0",
            upstream_label = "upstream/imgui",
            license_file = "LICENSE.txt",
        }],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "imguizmo",
            source_files = string.[
                "@imgui/imgui.cpp", "@imgui/imgui_draw.cpp",
                "@imgui/imgui_tables.cpp", "@imgui/imgui_widgets.cpp", "src/ImGuizmo.cpp",
            ],
            defines = string.[],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/imguizmo.git",
        supported_target = "linux-x64",
    };
}
