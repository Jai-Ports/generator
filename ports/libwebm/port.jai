libwebm_port :: () -> Port_Spec {
    return .{
        name = "libwebm",
        upstream_url = "https://chromium.googlesource.com/webm/libwebm",
        upstream_commit = "6184f4484a826724b5293837134ab9492261b941",
        upstream_label = "upstream/libwebm",
        license_file = "LICENSE.TXT",
        language = .CPP,
        standard = "c++11",
        include_directories = string.[],
        compiler_flags = string.["-I.", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "webm",
            source_files = string.["common/file_util.cc", "common/hdr_util.cc", "mkvmuxer/mkvmuxer.cc", "mkvmuxer/mkvmuxerutil.cc", "mkvmuxer/mkvwriter.cc", "mkvparser/mkvparser.cc", "mkvparser/mkvreader.cc"],
            defines = string.["__STDC_CONSTANT_MACROS", "__STDC_FORMAT_MACROS", "__STDC_LIMIT_MACROS"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/libwebm.git",
        supported_target = "linux-x64",
    };
}
