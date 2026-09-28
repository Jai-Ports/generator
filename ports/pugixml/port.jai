pugixml_port :: () -> Port_Spec {
    return .{
        name = "pugixml",
        upstream_url = "https://github.com/zeux/pugixml.git",
        upstream_commit = "27b68329de32cf9c601ca8eb6c588fd639960c40",
        upstream_label = "upstream/pugixml",
        license_file = "LICENSE.md",
        language = .CPP,
        standard = "c++11",
        include_directories = string.["src"],
        compiler_flags = string.["-fno-exceptions", "-fno-rtti", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "pugi",
            source_files = string.["src/pugixml.cpp"],
            defines = string.["PUGIXML_NO_STL", "PUGIXML_NO_EXCEPTIONS"],
            generated_entry = "pugixml.jai",
        }],
        output_url = "git@github.com:Jai-Ports/pugixml.git",
        supported_target = "linux-x64",
    };
}
