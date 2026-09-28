Port_Language :: enum u8 {
    C;
    CPP;
}

Port_Source_Group_Spec :: struct {
    source_files: [] string;
    include_directories: [] string;
    defines: [] string;
    compiler_flags: [] string;
}

Port_Module_Spec :: struct {
    // Empty for a package's root module, otherwise relative to the package.
    output_path: string;
    // Prefix used by the transpiler when producing readable public names.
    transpiler_prefix: string;

    source_files: [] string;
    // Concrete instantiations owned by this generator repository, relative to its root.
    // Their content hashes are recorded in package metadata.
    generator_source_files: [] string;
    // Pinned sources that require distinct flags, definitions or include order.
    source_groups: [] Port_Source_Group_Spec;
    // Use the exact per-source commands from these configured CMake targets.
    // Mutually exclusive with source_files; dependencies must be listed too.
    cmake_targets: [] string;
    make_targets: [] string;
    defines: [] string;
    compiler_flags: [] string;
    // Exact additional platform library paths or linker filenames. CMake
    // recipes also collect their configured transitive system link interface.
    system_libraries: [] string;
    generated_entry: string;
}

Port_Dependency_Spec :: struct {
    name: string;
    upstream_url: string;
    upstream_commit: string;
    upstream_label: string;
    license_file: string;
}

Port_Prepared_File_Spec :: struct {
    // Copy a file from pinned source into a managed include directory.
    source: string;
    destination: string;
}

Port_Submodule_Spec :: struct {
    // Name/path/URL must match .gitmodules; commit must match the pinned gitlink.
    name: string;
    path: string;
    upstream_url: string;
    upstream_commit: string;
    license_file: string;
}

Port_CMake_Source_Cache_Spec :: struct {
    key: string;
    // A pinned upstream-relative path or @dependency/path, resolved at runtime.
    source: string;
}

Port_CMake_Spec :: struct {
    enabled: bool;
    // Relative directory inside the pinned upstream checkout, if not its root.
    source_directory: string;
    // KEY=VALUE cache entries, passed as separate -D arguments.
    cache_variables: [] string;
    source_cache_variables: [] Port_CMake_Source_Cache_Spec;
    // Explicit generated-file or utility targets; never build the default all target.
    build_targets: [] string;
}

Port_Make_Spec :: struct {
    enabled: bool;
    // Executable from pinned source; always run in a fresh managed build directory.
    configure_script: string;
    configure_arguments: [] string;
    // KEY=VALUE arguments passed directly to Make, preserving per-source rules.
    variables: [] string;
    generated_targets: [] string;
}

Port_Spec :: struct {
    name: string;

    upstream_url: string;
    upstream_commit: string;
    upstream_label: string;
    license_file: string;

    language: Port_Language;
    standard: string;
    include_directories: [] string;
    compiler_flags: [] string;
    // Sources and include directories can reference @name/path in these pins.
    dependencies: [] Port_Dependency_Spec;
    submodules: [] Port_Submodule_Spec;
    prepared_files: [] Port_Prepared_File_Spec;
    cmake: Port_CMake_Spec;
    make: Port_Make_Spec;
    modules: [] Port_Module_Spec;

    output_url: string;
    supported_target: string;
}
