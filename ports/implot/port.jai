implot_port :: () -> Port_Spec {
    return .{
        name = "implot",
        upstream_url = "https://github.com/epezent/implot.git",
        upstream_commit = "7eeb9168d2e5e6b14e266d8782ecf7e649dfc3a4",
        upstream_label = "upstream/implot",
        license_file = "LICENSE",
        language = .CPP,
        standard = "c++11",
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
            transpiler_prefix = "implot",
            source_files = string.[
                "@imgui/imgui.cpp", "@imgui/imgui_draw.cpp",
                "@imgui/imgui_tables.cpp", "@imgui/imgui_widgets.cpp", "implot.cpp", "implot_items.cpp",
            ],
            defines = string.[],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/implot.git",
        supported_target = "linux-x64",
    };
}
