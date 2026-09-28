miniaudio_port :: () -> Port_Spec {
    return .{
        name = "miniaudio",
        upstream_url = "https://github.com/mackron/miniaudio.git",
        upstream_commit = "9634bedb5b5a2ca38c1ee7108a9358a4e233f14d",
        upstream_label = "upstream/miniaudio",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.[],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "ma",
            source_files = string.["miniaudio.h"],
            defines = string.["MINIAUDIO_IMPLEMENTATION"],
            generated_entry = "miniaudio.jai",
        }],
        output_url = "git@github.com:Jai-Ports/miniaudio.git",
        supported_target = "linux-x64",
    };
}
