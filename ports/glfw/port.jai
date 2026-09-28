glfw_port :: () -> Port_Spec {
    return .{
        name = "glfw",
        upstream_url = "https://github.com/glfw/glfw.git",
        upstream_commit = "92dcf4ce74f2e2554a98fea09be7c705c17daa5a",
        upstream_label = "upstream/glfw",
        license_file = "LICENSE.md",
        language = .C,
        standard = "c99 (upstream CMake)",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{
            enabled = true,
            cache_variables = string.["GLFW_BUILD_X11=ON", "GLFW_BUILD_WAYLAND=ON", "GLFW_BUILD_EXAMPLES=OFF", "GLFW_BUILD_TESTS=OFF", "GLFW_BUILD_DOCS=OFF"],
            build_targets = string.["src/wayland-client-protocol.h", "src/wayland-client-protocol-code.h", "src/viewporter-client-protocol.h", "src/viewporter-client-protocol-code.h", "src/xdg-shell-client-protocol.h", "src/xdg-shell-client-protocol-code.h", "src/idle-inhibit-unstable-v1-client-protocol.h", "src/idle-inhibit-unstable-v1-client-protocol-code.h", "src/pointer-constraints-unstable-v1-client-protocol.h", "src/pointer-constraints-unstable-v1-client-protocol-code.h", "src/relative-pointer-unstable-v1-client-protocol.h", "src/relative-pointer-unstable-v1-client-protocol-code.h", "src/fractional-scale-v1-client-protocol.h", "src/fractional-scale-v1-client-protocol-code.h", "src/xdg-activation-v1-client-protocol.h", "src/xdg-activation-v1-client-protocol-code.h", "src/xdg-decoration-unstable-v1-client-protocol.h", "src/xdg-decoration-unstable-v1-client-protocol-code.h"],
        },
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "glfw",
            cmake_targets = string.["glfw"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/glfw.git",
        supported_target = "linux-x64",
    };
}
