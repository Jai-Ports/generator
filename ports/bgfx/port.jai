bgfx_port :: () -> Port_Spec {
    return .{
        name = "bgfx",
        upstream_url = "https://github.com/bkaradzic/bgfx.git",
        upstream_commit = "81d81fba72c42d348c589514c774bbfe01e110fa",
        upstream_label = "upstream/bgfx",
        license_file = "LICENSE",
        language = .CPP,
        standard = "c++20",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        dependencies = Port_Dependency_Spec.[
            .{name="bx", upstream_url="https://github.com/bkaradzic/bx.git", upstream_commit="25315498841259323e18f549d1ad9d9aba6632cc", upstream_label="upstream/bx", license_file="LICENSE"},
            .{name="bimg", upstream_url="https://github.com/bkaradzic/bimg.git", upstream_commit="87aaad3ac882e741889fdd4263224e5d12c26f99", upstream_label="upstream/bimg", license_file="LICENSE"},
        ],
        modules = Port_Module_Spec.[.{
            transpiler_prefix = "bgfx",
            // Exact source/include/flag groups from the pinned Genie release64 graph.
            source_groups = Port_Source_Group_Spec.[
            .{
                source_files = string.["src/bgfx.cpp", "src/debug_renderdoc.cpp", "src/dxgi.cpp", "src/glcontext_egl.cpp", "src/glcontext_html5.cpp", "src/glcontext_wgl.cpp", "src/nvapi.cpp", "src/renderer_agc.cpp", "src/renderer_d3d11.cpp", "src/renderer_d3d12.cpp", "src/renderer_gl.cpp", "src/renderer_gnm.cpp", "src/renderer_mtl.cpp", "src/renderer_noop.cpp", "src/renderer_nvn.cpp", "src/renderer_vk.cpp", "src/renderer_webgpu.cpp", "src/shader.cpp", "src/topology.cpp", "src/vertexlayout.cpp", "src/video_d3d11.cpp", "src/video_d3d12.cpp", "src/video_mtl.cpp", "src/video_vk.cpp"],
                include_directories = string.["@bx/include/compat/linux", "3rdparty", "@bimg/include", "@bx/include", "3rdparty/directx-headers/include/directx", "3rdparty/directx-headers/include", "3rdparty/directx-headers/include/wsl/stubs", "3rdparty/khronos", "include"],
                defines = string.["__STDC_LIMIT_MACROS", "__STDC_FORMAT_MACROS", "__STDC_CONSTANT_MACROS", "NDEBUG", "BX_CONFIG_DEBUG=0"],
                compiler_flags = string.["-Wall", "-Wextra", "-g", "-O3", "-m64", "-fno-rtti", "-fno-exceptions", "-Wno-nan-infinity-disabled", "-Wno-tautological-constant-compare", "-msse4.2", "-Wshadow", "-Wunused-value", "-Wundef", "-m64", "-Wno-microsoft-enum-value", "-Wno-microsoft-const-init"],
            },
            .{
                source_files = string.["@bx/src/allocator.cpp", "@bx/src/bounds.cpp", "@bx/src/bx.cpp", "@bx/src/commandline.cpp", "@bx/src/crtnone.cpp", "@bx/src/debug.cpp", "@bx/src/dtoa.cpp", "@bx/src/easing.cpp", "@bx/src/file.cpp", "@bx/src/filepath.cpp", "@bx/src/hash.cpp", "@bx/src/math.cpp", "@bx/src/mutex.cpp", "@bx/src/os.cpp", "@bx/src/process.cpp", "@bx/src/scanner.cpp", "@bx/src/semaphore.cpp", "@bx/src/settings.cpp", "@bx/src/sort.cpp", "@bx/src/string.cpp", "@bx/src/thread.cpp", "@bx/src/timer.cpp", "@bx/src/url.cpp"],
                include_directories = string.["@bx/include/compat/linux", "@bx/include", "@bx/3rdparty"],
                defines = string.["__STDC_LIMIT_MACROS", "__STDC_FORMAT_MACROS", "__STDC_CONSTANT_MACROS", "NDEBUG", "BX_CONFIG_DEBUG=0"],
                compiler_flags = string.["-Wall", "-Wextra", "-g", "-O3", "-Werror", "-m64", "-fno-rtti", "-fno-exceptions", "-Wno-nan-infinity-disabled", "-Wno-tautological-constant-compare", "-msse4.2", "-Wshadow", "-Wunused-value", "-Wundef", "-m64", "-fPIC"],
            },
            .{
                source_files = string.["@bimg/3rdparty/astc-encoder/source/astcenc_averages_and_directions.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_block_sizes.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_color_quantize.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_color_unquantize.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_compress_symbolic.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_compute_variance.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_decompress_symbolic.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_diagnostic_trace.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_entry.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_find_best_partitioning.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_ideal_endpoints_and_weights.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_image.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_integer_sequence.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_mathlib.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_mathlib_softfloat.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_partition_tables.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_percentile_tables.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_pick_best_endpoint_format.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_quantization.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_symbolic_physical.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_weight_align.cpp", "@bimg/3rdparty/astc-encoder/source/astcenc_weight_quant_xfer_tables.cpp", "@bimg/src/image.cpp"],
                include_directories = string.["@bx/include/compat/linux", "@bimg/include", "@bimg/3rdparty/astc-encoder/include", "@bx/include"],
                defines = string.["__STDC_LIMIT_MACROS", "__STDC_FORMAT_MACROS", "__STDC_CONSTANT_MACROS", "NDEBUG", "ASTCENC_F16C=0", "ASTCENC_NEON=0", "BX_CONFIG_DEBUG=0"],
                compiler_flags = string.["-Wall", "-Wextra", "-g", "-O3", "-m64", "-fno-rtti", "-fno-exceptions", "-Wno-nan-infinity-disabled", "-Wno-tautological-constant-compare", "-msse4.2", "-Wshadow", "-Wunused-value", "-Wundef", "-m64", "-fPIC"],
            },
            ],
            system_libraries = string.["librt.so.1", "libdl.so.2"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/bgfx.git",
        supported_target = "linux-x64",
    };
}
