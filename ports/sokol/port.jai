sokol_port :: () -> Port_Spec {
    return .{
        name = "sokol",
        upstream_url = "https://github.com/floooh/sokol.git",
        upstream_commit = "2e75443dbd4940b5aa8d76a8e479f8e4b270b9a3",
        upstream_label = "upstream/sokol",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.[],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "args",
                transpiler_prefix = "sargs",
                source_files = string.["sokol_args.h"],
                defines = string.["SOKOL_IMPL"],
                generated_entry = "sokol_args.jai",
            },
            .{
                output_path = "time",
                transpiler_prefix = "stm",
                source_files = string.["sokol_time.h"],
                defines = string.["SOKOL_IMPL"],
                generated_entry = "sokol_time.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/sokol.git",
        supported_target = "linux-x64",
    };
}
