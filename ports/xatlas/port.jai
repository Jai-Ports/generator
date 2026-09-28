xatlas_port :: () -> Port_Spec {
    return .{
        name = "xatlas",

        upstream_url = "https://github.com/jpcy/xatlas.git",
        upstream_commit = "f700c7790aaa030e794b52ba7791a05c085faf0c",
        upstream_label = "upstream/xatlas",
        license_file = "LICENSE",

        language = .CPP,
        standard = "c++14",
        include_directories = string.["source/xatlas"],
        compiler_flags = string.[
            "-fno-exceptions",
            "-fno-rtti",
            "-fwrapv",
            "-ffp-contract=off",
        ],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "xatlas",
            source_files = string.["source/xatlas/xatlas.cpp"],
            defines = string.["XA_MULTITHREADED=0"],
            generated_entry = "xatlas.jai",
        }],

        output_url = "git@github.com:Jai-Ports/xatlas.git",
        supported_target = "linux-x64",
    };
}
