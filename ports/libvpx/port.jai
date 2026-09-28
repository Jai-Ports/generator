libvpx_port :: () -> Port_Spec {
    return .{
        name = "libvpx",
        upstream_url = "https://chromium.googlesource.com/webm/libvpx",
        upstream_commit = "5e680f30801d03c21078f8c4b772464752516211",
        upstream_label = "upstream/libvpx",
        license_file = "LICENSE",
        language = .C,
        standard = "upstream configure/Make",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        make = .{
            enabled = true,
            configure_script = "configure",
            configure_arguments = string.["--target=generic-gnu"],
            variables = string.["CC=clang", "CXX=clang++", "V=1", "target=libs"],
            generated_targets = string.["vp8_rtcd.h", "vp9_rtcd.h", "vpx_dsp_rtcd.h", "vpx_scale_rtcd.h"],
        },
        modules = Port_Module_Spec.[.{
            transpiler_prefix = "vpx",
            make_targets = string.["libvpx_g.a"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/libvpx.git",
        supported_target = "linux-x64",
    };
}
