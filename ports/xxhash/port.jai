xxhash_port :: () -> Port_Spec {
    return .{
        name = "xxhash",
        upstream_url = "https://github.com/Cyan4973/xxHash.git",
        upstream_commit = "680bf463fa1ca0461b9a7c2dab7556e1f54cf4cf",
        upstream_label = "upstream/xxhash",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.[],
        // Match the release oracle: upstream disables forced inline contracts
        // when Clang's default -O0 defines __NO_INLINE__.
        compiler_flags = string.["-x", "c", "-O3", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "xxh",
                source_files = string.["xxhash.c"],
                defines = string.[],
                generated_entry = "xxhash.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/xxhash.git",
        supported_target = "linux-x64",
    };
}
