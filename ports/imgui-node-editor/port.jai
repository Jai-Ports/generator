imgui_node_editor_port :: () -> Port_Spec {
    return .{
        name = "imgui-node-editor",
        upstream_url = "https://github.com/thedmd/imgui-node-editor.git",
        upstream_commit = "021aa0ea4da13fed864bafb2a92d4c5205076866",
        upstream_label = "upstream/imgui-node-editor",
        license_file = "LICENSE",
        language = .CPP,
        standard = "c++14",
        include_directories = string.["@imgui"],
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
            transpiler_prefix = "node_editor",
            source_files = string.[
                "@imgui/imgui.cpp", "@imgui/imgui_draw.cpp",
                "@imgui/imgui_tables.cpp", "@imgui/imgui_widgets.cpp", "imgui_node_editor.cpp", "imgui_node_editor_api.cpp", "imgui_canvas.cpp", "crude_json.cpp",
            ],
            defines = string.[],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/imgui-node-editor.git",
        supported_target = "linux-x64",
    };
}
