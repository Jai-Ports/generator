dr_libs_port :: () -> Port_Spec {
    return .{
        name = "dr_libs",
        upstream_url = "https://github.com/mackron/dr_libs.git",
        upstream_commit = "dfe8377631000664666519fdb83da193fd8037f4",
        upstream_label = "upstream/dr_libs",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.[],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "wav",
                transpiler_prefix = "drwav",
                source_files = string.["dr_wav.h"],
                defines = string.["DR_WAV_IMPLEMENTATION"],
                generated_entry = "dr_wav.jai",
            },
            .{
                output_path = "flac",
                transpiler_prefix = "drflac",
                source_files = string.["dr_flac.h"],
                defines = string.["DR_FLAC_IMPLEMENTATION"],
                generated_entry = "dr_flac.jai",
            },
            .{
                output_path = "mp3",
                transpiler_prefix = "drmp3",
                source_files = string.["dr_mp3.h"],
                defines = string.["DR_MP3_IMPLEMENTATION"],
                generated_entry = "dr_mp3.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/dr_libs.git",
        supported_target = "linux-x64",
    };
}
