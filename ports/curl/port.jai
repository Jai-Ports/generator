curl_port :: () -> Port_Spec {
    return .{
        name = "curl",
        upstream_url = "https://github.com/curl/curl.git",
        upstream_commit = "d87b4e4605132aa5f792a5955d648683277e593d",
        upstream_label = "upstream/curl",
        license_file = "COPYING",
        language = .C,
        standard = "upstream CMake",
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        cmake = .{enabled = true},
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "curl",
            cmake_targets = string.["libcurl_shared"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/curl.git",
        supported_target = "linux-x64",
    };
}
