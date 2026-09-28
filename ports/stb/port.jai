stb_port :: () -> Port_Spec {
    return .{
        name = "stb",

        upstream_url = "https://github.com/nothings/stb.git",
        upstream_commit = "2c980bb59875b0d32144a71867fbdebb2f77cd20",
        upstream_label = "upstream/stb",
        license_file = "LICENSE",

        language = .C,
        standard = "gnu11",
        include_directories = string.[],
        compiler_flags = string.["-x", "c", "-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "perlin",
                transpiler_prefix = "stb_perlin",
                source_files = string.["stb_perlin.h"],
                defines = string.["STB_PERLIN_IMPLEMENTATION"],
                generated_entry = "stb_perlin.jai",
            },
            .{
                output_path = "rect_pack",
                transpiler_prefix = "stbrp",
                source_files = string.["stb_rect_pack.h"],
                defines = string.["STB_RECT_PACK_IMPLEMENTATION"],
                generated_entry = "stb_rect_pack.jai",
            },
            .{
                output_path = "dxt",
                transpiler_prefix = "stb",
                source_files = string.["stb_dxt.h"],
                defines = string.["STB_DXT_IMPLEMENTATION"],
                compiler_flags = string.["-include", "string.h"],
                generated_entry = "stb_dxt.jai",
            },
            .{
                output_path = "image",
                transpiler_prefix = "stbi",
                source_files = string.["stb_image.h"],
                defines = string.["STB_IMAGE_IMPLEMENTATION"],
                generated_entry = "stb_image.jai",
            },
            .{
                output_path = "image_write",
                transpiler_prefix = "stbi_write",
                source_files = string.["stb_image_write.h"],
                defines = string.["STB_IMAGE_WRITE_IMPLEMENTATION"],
                generated_entry = "stb_image_write.jai",
            },
            .{
                output_path = "image_resize",
                transpiler_prefix = "stbir",
                source_files = string.["stb_image_resize2.h"],
                defines = string.["STB_IMAGE_RESIZE_IMPLEMENTATION"],
                generated_entry = "stb_image_resize2.jai",
            },
        ],

        output_url = "git@github.com:Jai-Ports/stb.git",
        supported_target = "linux-x64",
    };
}
