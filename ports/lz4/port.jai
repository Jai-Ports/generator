lz4_port :: () -> Port_Spec {
    return .{
        name = "lz4",
        upstream_url = "https://github.com/lz4/lz4.git",
        upstream_commit = "0774d05537f9762f838f7ab541b7765f1a729cb5",
        upstream_label = "upstream/lz4",
        license_file = "lib/LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.["lib"],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "lz4",
                source_files = string.["lib/lz4.c", "lib/lz4hc.c", "lib/lz4frame.c", "lib/xxhash.c"],
                defines = string.[],
                generated_entry = "cpp_transpiler_program.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/lz4.git",
        supported_target = "linux-x64",
    };
}
