vulkan_memory_allocator_port :: () -> Port_Spec {
    return .{
        name = "vulkan-memory-allocator",
        upstream_url = "https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator.git",
        upstream_commit = "3aa921224c154a0d2c43912bc88e1c42ce1f7607",
        upstream_label = "upstream/vulkan-memory-allocator",
        license_file = "LICENSE",
        language = .CPP,
        standard = "c++14",
        include_directories = string.["src", "include", "@vulkan-headers/include"],
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        dependencies = Port_Dependency_Spec.[.{
            name = "vulkan-headers",
            upstream_url = "https://github.com/KhronosGroup/Vulkan-Headers.git",
            upstream_commit = "6802bb4733b63ed5efd3adb308a6c885ef180ea1",
            upstream_label = "upstream/vulkan-headers",
            license_file = "LICENSE.md",
        }],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "vma",
            source_files = string.["src/VmaUsage.cpp"],
            defines = string.[],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/vulkan-memory-allocator.git",
        supported_target = "linux-x64",
    };
}
