Port_Language :: enum u8 {
    C;
    CPP;
}

Port_Spec :: struct {
    name: string;
    description: string;

    upstream_url: string;
    upstream_commit: string;
    upstream_label: string;
    license_file: string;

    language: Port_Language;
    standard: string;
    source_files: [] string;
    include_directories: [] string;
    defines: [] string;
    compiler_flags: [] string;

    generated_entry: string;
    output_repository: string;
    output_url: string;
    supported_target: string;
    verification_file: string;
}
