libyuv_port :: () -> Port_Spec {
    return .{
        name = "libyuv",
        upstream_url = "https://chromium.googlesource.com/libyuv/libyuv",
        upstream_commit = "7c85a3a0820fab29abb502c207d8b9a394e352cc",
        upstream_label = "upstream/libyuv",
        license_file = "LICENSE",
        language = .CPP,
        standard = "c++11",
        include_directories = string.["include"],
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[
            .{
                output_path = "",
                transpiler_prefix = "libyuv",
                source_files = string.["source/compare.cc", "source/compare_common.cc", "source/convert.cc", "source/convert_argb.cc", "source/convert_from.cc", "source/convert_from_argb.cc", "source/convert_jpeg.cc", "source/convert_to_argb.cc", "source/convert_to_i420.cc", "source/cpu_id.cc", "source/mjpeg_decoder.cc", "source/mjpeg_validate.cc", "source/planar_functions.cc", "source/rotate.cc", "source/rotate_any.cc", "source/rotate_argb.cc", "source/rotate_common.cc", "source/row_any.cc", "source/row_common.cc", "source/scale.cc", "source/scale_any.cc", "source/scale_argb.cc", "source/scale_common.cc", "source/scale_rgb.cc", "source/scale_uv.cc", "source/video_common.cc"],
                // Select libyuv's upstream portable profile. This disables
                // architecture assembly kernels and their runtime CPU probe.
                defines = string.["__pnacl__"],
                generated_entry = "cpp_transpiler_program.jai",
            },
        ],
        output_url = "git@github.com:Jai-Ports/libyuv.git",
        supported_target = "linux-x64",
    };
}
