fastnoise_port :: () -> Port_Spec {
    return .{
        name = "fastnoise",
        upstream_url = "https://github.com/Auburn/FastNoiseLite.git",
        upstream_commit = "785f37a9ad76e283586a379675085f2063ae03f7",
        upstream_label = "upstream/fastnoise",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.["C"],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "fnl",
                source_files = string.["C/FastNoiseLite.h"],
                defines = string.["FNL_IMPL"],
                generated_entry = "FastNoiseLite.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/fastnoise.git",
        supported_target = "linux-x64",
    };
}
