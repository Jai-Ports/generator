meshoptimizer_port :: () -> Port_Spec {
    return .{
        name = "meshoptimizer",
        upstream_url = "https://github.com/zeux/meshoptimizer.git",
        upstream_commit = "717ca3489b457f781e5cd3e3a8bbc0229619415c",
        upstream_label = "upstream/meshoptimizer",
        license_file = "LICENSE.md",
        language = .CPP,
        standard = "c++11",
        include_directories = string.["src"],
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "meshopt",
            source_files = string.[
                "src/allocator.cpp", "src/clusterizer.cpp", "src/indexanalyzer.cpp",
                "src/indexcodec.cpp", "src/indexgenerator.cpp", "src/meshletcodec.cpp",
                "src/meshletutils.cpp", "src/opacitymap.cpp", "src/overdrawoptimizer.cpp",
                "src/partition.cpp", "src/quantization.cpp", "src/rasterizer.cpp",
                "src/remesher.cpp", "src/simplifier.cpp", "src/spatialorder.cpp",
                "src/stripifier.cpp", "src/tangentspace.cpp", "src/vcacheoptimizer.cpp",
                "src/vertexcodec.cpp", "src/vertexfilter.cpp", "src/vfetchoptimizer.cpp",
            ],
            defines = string.[],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/meshoptimizer.git",
        supported_target = "linux-x64",
    };
}
