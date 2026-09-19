xatlas_port :: () -> Port_Spec {
    return .{
        name = "xatlas",
        description = "Jai translation of the xatlas UV atlas generation library",

        upstream_url = "https://github.com/jpcy/xatlas.git",
        upstream_commit = "f700c7790aaa030e794b52ba7791a05c085faf0c",
        upstream_label = "upstream/xatlas",
        license_file = "LICENSE",

        language = .CPP,
        standard = "c++14",
        source_files = string.["source/xatlas/xatlas.cpp"],
        include_directories = string.["source/xatlas"],
        defines = string.["XA_MULTITHREADED=0"],
        compiler_flags = string.[
            "-fno-exceptions",
            "-fno-rtti",
            "-fwrapv",
            "-ffp-contract=off",
        ],

        generated_entry = "xatlas.jai",
        output_repository = "out/xatlas",
        output_url = "git@github.com:Jai-Ports/xatlas.git",
        supported_target = "linux-x64",
        verification_file = "tests/xatlas.jai",
    };
}
