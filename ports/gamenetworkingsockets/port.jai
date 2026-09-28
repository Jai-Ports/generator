gamenetworkingsockets_port :: () -> Port_Spec {
    return .{
        name = "gamenetworkingsockets",
        upstream_url = "https://github.com/ValveSoftware/GameNetworkingSockets.git",
        upstream_commit = "a424b7db649438acafb60c99cae6667587c42732",
        upstream_label = "upstream/gamenetworkingsockets",
        license_file = "LICENSE",
        language = .CPP,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true, build_targets = string.["src/steamnetworkingsockets_messages_certs.pb.cc", "src/steamnetworkingsockets_messages.pb.cc", "src/steamnetworkingsockets_messages_udp.pb.cc"]},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "GameNetworkingSockets",
            cmake_targets = string.["GameNetworkingSockets"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/gamenetworkingsockets.git",
        supported_target = "linux-x64",
    };
}
