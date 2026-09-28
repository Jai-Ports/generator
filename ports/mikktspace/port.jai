mikktspace_port :: () -> Port_Spec {
    return .{
        name = "mikktspace",
        upstream_url = "https://github.com/mmikk/MikkTSpace.git",
        upstream_commit = "3e895b49d05ea07e4c2133156cfa94369e19e409",
        upstream_label = "upstream/mikktspace",
        license_file = "mikktspace.h",
        language = .C,
        standard = "gnu11",
        include_directories = string.[],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "mikk",
                source_files = string.["mikktspace.c"],
                defines = string.[],
                generated_entry = "mikktspace.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/mikktspace.git",
        supported_target = "linux-x64",
    };
}
