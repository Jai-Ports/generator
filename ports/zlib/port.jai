zlib_port :: () -> Port_Spec {
    return .{
        name = "zlib",
        upstream_url = "https://github.com/madler/zlib.git",
        upstream_commit = "767c4c947852e143f582c85f14cf573411df1b35",
        upstream_label = "upstream/zlib",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.[],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "zlib",
                source_files = string.["adler32.c", "compress.c", "crc32.c", "deflate.c", "gzclose.c", "gzlib.c", "gzread.c", "gzwrite.c", "infback.c", "inffast.c", "inflate.c", "inftrees.c", "trees.c", "uncompr.c", "zutil.c"],
                defines = string.["HAVE_UNISTD_H=1"],
                generated_entry = "cpp_transpiler_program.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/zlib.git",
        supported_target = "linux-x64",
    };
}
