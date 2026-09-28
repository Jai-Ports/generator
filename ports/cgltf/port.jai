cgltf_port :: () -> Port_Spec {
    return .{
        name = "cgltf",
        upstream_url = "https://github.com/jkuhlmann/cgltf.git",
        upstream_commit = "85cd62382dfea638278962690cf515023f33ed00",
        upstream_label = "upstream/cgltf",
        license_file = "LICENSE",
        language = .C,
        standard = "gnu11",
        include_directories = string.[],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "cgltf",
                source_files = string.["cgltf_write.h"],
                defines = string.["CGLTF_IMPLEMENTATION", "CGLTF_WRITE_IMPLEMENTATION"],
                generated_entry = "cgltf_write.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/cgltf.git",
        supported_target = "linux-x64",
    };
}
