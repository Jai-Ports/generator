zstd_port :: () -> Port_Spec {
    return .{
        name = "zstd",
        upstream_url = "https://github.com/facebook/zstd.git",
        upstream_commit = "01b7154f1172432f8abe9b3bb9909e14a1176b7d",
        upstream_label = "upstream/zstd",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.["lib", "lib/common"],
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "zstd",
            source_files = string.["lib/common/debug.c", "lib/common/entropy_common.c", "lib/common/error_private.c", "lib/common/fse_decompress.c", "lib/common/pool.c", "lib/common/threading.c", "lib/common/xxhash.c", "lib/common/zstd_common.c", "lib/compress/fse_compress.c", "lib/compress/hist.c", "lib/compress/huf_compress.c", "lib/compress/zstd_compress.c", "lib/compress/zstd_compress_literals.c", "lib/compress/zstd_compress_sequences.c", "lib/compress/zstd_compress_superblock.c", "lib/compress/zstd_double_fast.c", "lib/compress/zstd_fast.c", "lib/compress/zstd_lazy.c", "lib/compress/zstd_ldm.c", "lib/compress/zstd_opt.c", "lib/compress/zstd_preSplit.c", "lib/compress/zstdmt_compress.c", "lib/decompress/huf_decompress.c", "lib/decompress/zstd_ddict.c", "lib/decompress/zstd_decompress.c", "lib/decompress/zstd_decompress_block.c", "lib/dictBuilder/cover.c", "lib/dictBuilder/divsufsort.c", "lib/dictBuilder/fastcover.c", "lib/dictBuilder/zdict.c"],
            defines = string.["ZSTD_DISABLE_ASM", "ZSTD_MULTITHREAD", "ZSTD_LEGACY_SUPPORT=0"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/zstd.git",
        supported_target = "linux-x64",
    };
}
