ufbx_port :: () -> Port_Spec {
    return .{
        name = "ufbx",
        upstream_url = "https://github.com/ufbx/ufbx.git",
        upstream_commit = "fcc5d6ba444cfd3eb80677dba5e37e493941abe5",
        upstream_label = "upstream/ufbx",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.[],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "ufbx",
                source_files = string.["ufbx.c"],
                defines = string.["UFBX_ENABLE_ERROR_STACK=1"],
                generated_entry = "ufbx.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/ufbx.git",
        supported_target = "linux-x64",
    };
}
