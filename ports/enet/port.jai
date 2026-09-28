enet_port :: () -> Port_Spec {
    return .{
        name = "enet",

        upstream_url = "https://github.com/lsalzman/enet.git",
        upstream_commit = "5a9c537fd464b3c6d3c55e1d3bd47588faf71b42",
        upstream_label = "upstream/enet",
        license_file = "LICENSE",

        language = .C,
        standard = "gnu11",
        include_directories = string.["include"],
        compiler_flags = string.[],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "enet",
            source_files = string.[
                "callbacks.c",
                "compress.c",
                "host.c",
                "list.c",
                "packet.c",
                "peer.c",
                "protocol.c",
                "unix.c",
            ],
            defines = string.[
                "_GNU_SOURCE=1",
                "HAS_FCNTL=1",
                "HAS_POLL=1",
                "HAS_GETADDRINFO=1",
                "HAS_GETNAMEINFO=1",
                "HAS_GETHOSTBYNAME_R=1",
                "HAS_GETHOSTBYADDR_R=1",
                "HAS_INET_PTON=1",
                "HAS_INET_NTOP=1",
                "HAS_OFFSETOF=1",
                "HAS_MSGHDR_FLAGS=1",
                "HAS_SOCKLEN_T=1",
            ],
            generated_entry = "cpp_transpiler_program.jai",
        }],

        output_url = "git@github.com:Jai-Ports/enet.git",
        supported_target = "linux-x64",
    };
}
