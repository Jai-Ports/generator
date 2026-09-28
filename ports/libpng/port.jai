libpng_port :: () -> Port_Spec {
    return .{
        name = "libpng",
        upstream_url = "https://github.com/pnggroup/libpng.git",
        upstream_commit = "964b4135949703b705fc760fc3fb546b86e5ab47",
        upstream_label = "upstream/libpng",
        license_file = "LICENSE.md",
        language = .C,
        standard = "gnu11",
        include_directories = string.["@zlib"],
        compiler_flags = string.["-I.", "-fwrapv", "-ffp-contract=off"],
        prepared_files = Port_Prepared_File_Spec.[.{
            source = "pnglibconf.h.prebuilt", destination = "pnglibconf.h",
        }],
        dependencies = Port_Dependency_Spec.[.{
            name = "zlib",
            upstream_url = "https://github.com/madler/zlib.git",
            upstream_commit = "767c4c947852e143f582c85f14cf573411df1b35",
            upstream_label = "upstream/zlib",
            license_file = "LICENSE",
        }],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "png",
                source_files = string.["png.c", "pngerror.c", "pngget.c", "pngmem.c", "pngpread.c", "pngread.c", "pngrio.c", "pngrtran.c", "pngrutil.c", "pngset.c", "pngtrans.c", "pngwio.c", "pngwrite.c", "pngwtran.c", "pngwutil.c", "pngsimd.c", "@zlib/adler32.c", "@zlib/compress.c", "@zlib/crc32.c", "@zlib/deflate.c", "@zlib/gzclose.c", "@zlib/gzlib.c", "@zlib/gzread.c", "@zlib/gzwrite.c", "@zlib/infback.c", "@zlib/inffast.c", "@zlib/inflate.c", "@zlib/inftrees.c", "@zlib/trees.c", "@zlib/uncompr.c", "@zlib/zutil.c"],
                defines = string.["HAVE_UNISTD_H=1"],
                generated_entry = "cpp_transpiler_program.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/libpng.git",
        supported_target = "linux-x64",
    };
}
