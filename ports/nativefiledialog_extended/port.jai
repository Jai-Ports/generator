nativefiledialog_extended_port :: () -> Port_Spec {
    return .{
        name = "nativefiledialog_extended",
        upstream_url = "https://github.com/btzy/nativefiledialog-extended.git",
        upstream_commit = "5381ddbf0b33d3b7b4c5679b0e796d77848a158d",
        upstream_label = "upstream/nativefiledialog_extended",
        license_file = "LICENSE",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        submodules = Port_Submodule_Spec.[.{
            name = "3ps/wayland-protocols", path = "3ps/wayland-protocols",
            upstream_url = "https://gitlab.freedesktop.org/wayland/wayland-protocols.git",
            upstream_commit = "88223018d1b578d0d8869866da66d9608e05f928",
            license_file = "COPYING",
        }],
        cmake = .{
            enabled = true,
            cache_variables = string.["NFD_X11=ON", "NFD_WAYLAND=ON"],
            build_targets = string.["src/xdg-foreign-unstable-v1.h", "src/xdg-foreign-unstable-v1.c"],
        },
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "NFD",
            cmake_targets = string.["nfd"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/nativefiledialog-extended.git",
        supported_target = "linux-x64",
    };
}
