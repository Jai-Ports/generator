yyjson_port :: () -> Port_Spec {
    return .{
        name = "yyjson",
        upstream_url = "https://github.com/ibireme/yyjson.git",
        upstream_commit = "6447536015f3d600f3d65323b10976103b337ca7",
        upstream_label = "upstream/yyjson",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.["src"],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "yyjson",
                source_files = string.["src/yyjson.c"],
                defines = string.[],
                generated_entry = "yyjson.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/yyjson.git",
        supported_target = "linux-x64",
    };
}
