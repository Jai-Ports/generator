File_Utilities :: #import "File_Utilities";

GENERATOR_SOURCE_DIRECTORY :: #filepath;
GENERATOR_REPOSITORY_URL :: "https://github.com/Jai-Ports/generator.git";
#if OS == .LINUX {
    GENERATOR_JAI_EXECUTABLE :: "jai-linux";
} else #if OS == .MACOS {
    GENERATOR_JAI_EXECUTABLE :: "jai-macos";
} else #if OS == .WINDOWS {
    GENERATOR_JAI_EXECUTABLE :: "jai.exe";
} else {
    GENERATOR_JAI_EXECUTABLE :: "";
    #assert(false, "the generator requires a desktop Jai compiler");
}
GENERATOR_INPUT_SUBMODULES :: string.[
    "src/tbx/transpiler",
    "src/tbx/arena",
    "src/tbx/json",
];

Generator_Options :: struct {
    offline: bool;
}

Generator_Provenance :: struct {
    commit: string;
    has_commit: bool;
    dirty: bool;
}

deinit :: (provenance: *Generator_Provenance) {
    if provenance == null return;
    if provenance.commit.data port_owned_string_drop(*provenance.commit);
    provenance.* = .{};
}

generator_error :: (message: string) {
    write_string(tprint("error: %\n", message), to_standard_error = true);
    exit(1);
}

generator_process_succeeded :: (result: *Translator_Process_Output_Result) -> bool {
    return result.process.type == .EXITED && result.process.exit_code == 0;
}

generator_run_checked :: (
    arguments: [] string,
    working_directory: string,
    stage: string,
) {
    result := translator_process_run_output(arguments, working_directory);
    defer translator_process_output_result_deinit(*result);
    if generator_process_succeeded(*result) return;

    write_string(tprint("error: % failed\n", stage), to_standard_error = true);
    if result.launch_error
        write_string(tprint("launch error: %\n", result.launch_error), to_standard_error = true);
    if result.output.count write_string(result.output, to_standard_error = true);
    if result.error.count write_string(result.error, to_standard_error = true);
    exit(1);
}

generator_run_capture :: (
    arguments: [] string,
    working_directory: string,
    stage: string,
) -> string {
    result := translator_process_run_output(arguments, working_directory);
    defer translator_process_output_result_deinit(*result);
    if !generator_process_succeeded(*result) {
        write_string(tprint("error: % failed\n", stage), to_standard_error = true);
        if result.launch_error
            write_string(tprint("launch error: %\n", result.launch_error), to_standard_error = true);
        if result.output.count write_string(result.output, to_standard_error = true);
        if result.error.count write_string(result.error, to_standard_error = true);
        exit(1);
    }
    return copy_string(result.output);
}

generator_try_capture :: (
    arguments: [] string,
    working_directory: string,
) -> (string, bool) {
    result := translator_process_run_output(arguments, working_directory);
    succeeded := generator_process_succeeded(*result);
    output := copy_string(ifx succeeded then result.output else "");
    translator_process_output_result_deinit(*result);
    return output, succeeded;
}

generator_trim_line_endings :: (value: string) -> string {
    result := value;
    while result.count &&
          (result[result.count - 1] == #char "\n" ||
           result[result.count - 1] == #char "\r") result.count -= 1;
    return result;
}

generator_string_ends_with :: (value: string, suffix: string) -> bool {
    if suffix.count > value.count return false;
    offset := value.count - suffix.count;
    for byte, index: suffix if value[offset + index] != byte return false;
    return true;
}

generator_string_starts_with :: (value: string, prefix: string) -> bool {
    if prefix.count > value.count return false;
    for byte, index: prefix if value[index] != byte return false;
    return true;
}

generator_identifier_start :: (byte: u8) -> bool {
    return byte == #char "_" ||
           (byte >= #char "a" && byte <= #char "z") ||
           (byte >= #char "A" && byte <= #char "Z");
}

generator_identifier_continue :: (byte: u8) -> bool {
    return generator_identifier_start(byte) ||
           (byte >= #char "0" && byte <= #char "9");
}

Generator_Internal_Name :: struct {
    original: string;
    canonical: string;
}

generator_internal_name_has_numeric_suffix :: (identifier: string) -> bool {
    if !generator_string_starts_with(identifier, "cpp_transpiler_") &&
       !generator_string_starts_with(identifier, "temporary_") return false;
    separator := identifier.count - 1;
    while separator >= 0 && identifier[separator] >= #char "0" &&
          identifier[separator] <= #char "9" separator -= 1;
    return separator >= 0 && separator + 1 < identifier.count &&
           identifier[separator] == #char "_";
}

// Clang protocol IDs are stable inside one AST, but a few synthesized IDs can
// be allocated in either order across otherwise identical exporter runs. They
// only appear in private generated temporary names. Canonicalize those names
// by first appearance so output repositories remain byte-for-byte reproducible.
generator_canonicalize_internal_names :: (source: string) -> string {
    names: [..] Generator_Internal_Name;
    defer {
        for *name: names {
            port_owned_string_drop(*name.original);
            port_owned_string_drop(*name.canonical);
        }
        array_free(names);
    }

    output: String_Builder;
    cursor := 0;
    while cursor < source.count {
        if !generator_identifier_start(source[cursor]) {
            append(*output, source[cursor]);
            cursor += 1;
            continue;
        }
        end := cursor + 1;
        while end < source.count && generator_identifier_continue(source[end]) end += 1;
        identifier := compat_string_slice(source, cursor, end);
        if !generator_internal_name_has_numeric_suffix(identifier) {
            append(*output, identifier);
            cursor = end;
            continue;
        }

        replacement := "";
        for *name: names if name.original == identifier {
            replacement = name.canonical;
            break;
        }
        if !replacement.count {
            separator := identifier.count - 1;
            while identifier[separator] >= #char "0" &&
                  identifier[separator] <= #char "9" separator -= 1;
            base := compat_string_slice(identifier, 0, separator + 1);
            replacement = copy_string(tprint("%g%", base, names.count));
            array_add(*names, .{
                original = copy_string(identifier),
                canonical = replacement,
            });
        }
        append(*output, replacement);
        cursor = end;
    }
    return builder_to_string(*output);
}

generator_repository_root :: () -> string {
    candidate := tprint("%/../..", GENERATOR_SOURCE_DIRECTORY);
    root, ok := File.get_absolute_path(candidate);
    if !ok generator_error(tprint("could not resolve generator root from %", candidate));
    return root;
}

generator_repository_input_status :: (root: string) -> string {
    return generator_run_capture(
        string.[
            "git", "-C", root, "status", "--porcelain",
            "--untracked-files=all", "--",
            ".gitmodules", "build.jai", "src", "ports", "tests",
        ],
        root,
        "inspect generator inputs",
    );
}

generator_append_status_section :: (
    builder: *String_Builder,
    label: string,
    status: string,
) {
    if !status.count return;
    append(builder, label);
    append(builder, ":\n");
    append(builder, status);
    if status[status.count - 1] != #char "\n" append(builder, #char "\n");
}

generator_generation_input_status :: (root: string) -> string {
    builder: String_Builder;

    root_status := generator_repository_input_status(root);
    defer port_owned_string_drop(*root_status);
    generator_append_status_section(*builder, "generator repository", root_status);

    for relative_path: GENERATOR_INPUT_SUBMODULES {
        repository := tprint("%/%", root, relative_path);
        status := generator_run_capture(
            string.[
                "git", "-C", repository, "status", "--porcelain",
                "--untracked-files=all",
            ],
            root,
            tprint("inspect %", relative_path),
        );
        defer port_owned_string_drop(*status);
        generator_append_status_section(*builder, relative_path, status);
    }

    return builder_to_string(*builder);
}

generator_read_provenance :: (root: string) -> Generator_Provenance {
    commit_output, has_commit := generator_try_capture(
        string.["git", "-C", root, "rev-parse", "HEAD"], root,
    );
    defer port_owned_string_drop(*commit_output);
    commit := ifx has_commit
        then copy_string(generator_trim_line_endings(commit_output))
        else copy_string("");

    status := generator_generation_input_status(root);
    defer port_owned_string_drop(*status);
    return .{
        commit = commit,
        has_commit = has_commit,
        dirty = !has_commit || status.count != 0,
    };
}

generator_require_managed_relative_path :: (value: string, label: string) {
    if !value.count || value[0] == #char "/"
        generator_error(tprint("% must be a non-empty relative path: %", label, value));
    components := compat_string_split(value, "/");
    defer array_free(components);
    for component: components {
        if component == "" || component == "." || component == ".."
            generator_error(tprint("% contains an unsafe path component: %", label, value));
    }
}

generator_json_append_string :: (builder: *String_Builder, value: string) {
    append(builder, #char "\"");
    for byte: value {
        if byte == #char "\"" append(builder, "\\\"");
        else if byte == #char "\\" append(builder, "\\\\");
        else if byte == #char "\n" append(builder, "\\n");
        else if byte == #char "\r" append(builder, "\\r");
        else if byte == #char "\t" append(builder, "\\t");
        else {
            if byte < 0x20 generator_error("port metadata contains an unsupported control character");
            append(builder, byte);
        }
    }
    append(builder, #char "\"");
}

generator_json_append_array :: (builder: *String_Builder, values: [] string, indent: string) {
    append(builder, "[\n");
    for value, index: values {
        append(builder, indent);
        generator_json_append_string(builder, value);
        if index + 1 < values.count append(builder, #char ",");
        append(builder, #char "\n");
    }
    if indent.count >= 2 append(builder, compat_string_slice(indent, 0, indent.count - 2));
    append(builder, #char "]");
}

generator_find_port :: (name: string) -> (Port_Spec, bool) {
    if name == "xatlas" return xatlas_port(), true;
    return .{}, false;
}

generator_list_ports :: () {
    port := xatlas_port();
    print("%\t%\t%\n", port.name, port.upstream_commit, port.description);
}

generator_prepare_upstream :: (
    root: string,
    port: *Port_Spec,
    offline: bool,
) -> string {
    generator_require_managed_relative_path(port.name, "port name");
    cache_parent := tprint("%/.cache/upstream", root);
    assert(File.make_directory_if_it_does_not_exist(cache_parent, recursive = true));
    checkout := tprint("%/%", cache_parent, port.name);

    if !compat_path_exists(checkout) {
        if offline generator_error(tprint(
            "upstream cache is missing for %; rerun without --offline", port.name,
        ));
        print("Fetching % upstream repository...\n", port.name);
        generator_run_checked(
            string.["git", "clone", "--filter=blob:none", "--no-checkout",
                    port.upstream_url, checkout],
            root,
            tprint("clone %", port.name),
        );
    }

    if !compat_path_exists(tprint("%/.git", checkout))
        generator_error(tprint("upstream cache is not a Git checkout: %", checkout));

    commit_probe := translator_process_run_output(
        string.["git", "-C", checkout, "cat-file", "-e",
                tprint("%^{commit}", port.upstream_commit)],
        root,
    );
    commit_present := generator_process_succeeded(*commit_probe);
    translator_process_output_result_deinit(*commit_probe);
    if !commit_present {
        if offline generator_error(tprint(
            "cached % checkout does not contain %; rerun without --offline",
            port.name, port.upstream_commit,
        ));
        print("Fetching pinned % commit %...\n", port.name, port.upstream_commit);
        generator_run_checked(
            string.["git", "-C", checkout, "fetch", "--depth", "1", "origin",
                    port.upstream_commit],
            root,
            tprint("fetch %", port.name),
        );
    }

    generator_run_checked(
        string.["git", "-C", checkout, "checkout", "--detach", port.upstream_commit],
        root,
        tprint("checkout %", port.name),
    );

    revision_output := generator_run_capture(
        string.["git", "-C", checkout, "rev-parse", "HEAD"], root,
        tprint("verify % revision", port.name),
    );
    defer port_owned_string_drop(*revision_output);
    if generator_trim_line_endings(revision_output) != port.upstream_commit
        generator_error(tprint("% resolved to the wrong revision", port.name));

    status_output := generator_run_capture(
        string.["git", "-C", checkout, "status", "--porcelain",
                "--untracked-files=all"],
        root,
        tprint("verify % checkout", port.name),
    );
    defer port_owned_string_drop(*status_output);
    if status_output.count generator_error(tprint(
        "managed upstream checkout is dirty: %\n%", checkout, status_output,
    ));

    return checkout;
}

generator_write_compile_database :: (
    path: string,
    source_root: string,
    port: *Port_Spec,
) {
    builder: String_Builder;
    append(*builder, "[\n");
    for source_file, source_index: port.source_files {
        generator_require_managed_relative_path(source_file, "source file");
        source_path := tprint("%/%", source_root, source_file);
        if !compat_path_exists(source_path)
            generator_error(tprint("configured source file does not exist: %", source_path));

        arguments: [..] string;
        array_add(*arguments, "clang++");
        array_add(*arguments, tprint("-std=%", port.standard));
        for flag: port.compiler_flags array_add(*arguments, flag);
        for define: port.defines array_add(*arguments, tprint("-D%", define));
        for include_directory: port.include_directories {
            generator_require_managed_relative_path(include_directory, "include directory");
            array_add(*arguments, tprint("-I%/%", source_root, include_directory));
        }
        array_add(*arguments, "-c");
        array_add(*arguments, source_path);

        append(*builder, "  {\n    \"directory\": ");
        generator_json_append_string(*builder, source_root);
        append(*builder, ",\n    \"file\": ");
        generator_json_append_string(*builder, source_path);
        append(*builder, ",\n    \"arguments\": ");
        generator_json_append_array(*builder, arguments, "      ");
        append(*builder, "\n  }");
        if source_index + 1 < port.source_files.count append(*builder, #char ",");
        append(*builder, #char "\n");
        array_free(arguments);
    }
    append(*builder, "]\n");
    assert(File.write_entire_file(path, *builder));
}

generator_transpile :: (
    root: string,
    port: *Port_Spec,
    compile_database: string,
    output_directory: string,
) {
    if port.language != .CPP generator_error("the first generator slice supports C++ ports only");

    transpiler_directory := tprint("%/src/tbx/transpiler", root);
    cpp_exporter := tprint(
        "%/host_libraries/libclangCppAstExporter.so", transpiler_directory,
    );
    if !compat_path_exists(cpp_exporter)
        generator_error("transpiler host libraries are missing; run ./scripts/bootstrap.sh");

    previous_directory := get_working_directory();
    if !set_working_directory(transpiler_directory)
        generator_error(tprint("could not enter transpiler directory: %", transpiler_directory));
    defer assert(set_working_directory(previous_directory));

    if !cpp_clang_exporter_load_native()
        generator_error("could not load libclangCppAstExporter.so");

    config: Cpp_Transpiler_Config;
    config.fail_on_error = true;
    config.overwrite_existing = true;
    config.emission_profile = .OPTIMIZED;
    config.procedure_abi = .JAI;
    config.module_name = port_optional_some(copy_string(port.name));
    config.output_directory = port_optional_some(copy_string(output_directory));
    cpp_transpiler_run(config, compile_database, .[]);
}

Generator_Copy_Arguments :: struct {
    destination: string;
    source_root: string;
    upstream_label: string;
    copied_count: int;
}

generator_copy_transpiled_output :: (
    transpiled_source_directory: string,
    generated_destination: string,
    source_root: string,
    upstream_label: string,
) {
    args := Generator_Copy_Arguments.{
        destination = generated_destination,
        source_root = source_root,
        upstream_label = upstream_label,
    };
    visitor :: (info: *File_Utilities.File_Visit_Info, args: *Generator_Copy_Arguments) {
        if info.is_directory || !generator_string_ends_with(info.short_name, ".jai") return;
        contents, ok := File.read_entire_file(info.full_name);
        if !ok generator_error(tprint("could not read transpiler output: %", info.full_name));
        defer free(contents.data);
        path_normalized := cpp_jai_replace_all(contents, args.source_root, args.upstream_label);
        defer port_owned_string_drop(*path_normalized);
        normalized := generator_canonicalize_internal_names(path_normalized);
        defer port_owned_string_drop(*normalized);
        destination := tprint("%/%", args.destination, info.short_name);
        if !File.write_entire_file(destination, normalized)
            generator_error(tprint("could not write packaged source: %", destination));
        args.copied_count += 1;
    }
    if !File_Utilities.visit_files(
        transpiled_source_directory, true, *args, visitor,
        visit_files = true, visit_directories = false,
    ) generator_error(tprint("could not enumerate %", transpiled_source_directory));
    if args.copied_count == 0 generator_error("transpiler produced no Jai source files");
}

generator_write_port_metadata :: (
    path: string,
    port: *Port_Spec,
    provenance: *Generator_Provenance,
) {
    builder: String_Builder;
    append(*builder, "{\n  \"schema_version\": 2,\n  \"name\": ");
    generator_json_append_string(*builder, port.name);
    append(*builder, ",\n  \"description\": ");
    generator_json_append_string(*builder, port.description);
    append(*builder, ",\n  \"upstream\": {\n    \"url\": ");
    generator_json_append_string(*builder, port.upstream_url);
    append(*builder, ",\n    \"commit\": ");
    generator_json_append_string(*builder, port.upstream_commit);
    append(*builder, "\n  },\n  \"generator\": {\n    \"repository\": ");
    generator_json_append_string(*builder, GENERATOR_REPOSITORY_URL);
    append(*builder, ",\n    \"commit\": ");
    if provenance.has_commit && !provenance.dirty
        generator_json_append_string(*builder, provenance.commit);
    else append(*builder, "null");
    append(*builder, "\n  }");
    append(*builder, ",\n  \"language\": \"c++\",\n  \"standard\": ");
    generator_json_append_string(*builder, port.standard);
    append(*builder, ",\n  \"supported_target\": ");
    generator_json_append_string(*builder, port.supported_target);
    append(*builder, ",\n  \"sources\": ");
    generator_json_append_array(*builder, port.source_files, "    ");
    append(*builder, ",\n  \"include_directories\": ");
    generator_json_append_array(*builder, port.include_directories, "    ");
    append(*builder, ",\n  \"defines\": ");
    generator_json_append_array(*builder, port.defines, "    ");
    append(*builder, ",\n  \"compiler_flags\": ");
    generator_json_append_array(*builder, port.compiler_flags, "    ");
    append(*builder, "\n}\n");
    assert(File.write_entire_file(path, *builder));
}

generator_assemble_package :: (
    root: string,
    port: *Port_Spec,
    source_root: string,
    transpiled_directory: string,
    package_directory: string,
    provenance: *Generator_Provenance,
) {
    package_source_directory := tprint("%/src", package_directory);
    assert(File.make_directory_if_it_does_not_exist(package_source_directory, recursive = true));

    transpiled_source_directory := tprint("%/src", transpiled_directory);
    generator_copy_transpiled_output(
        transpiled_source_directory, package_source_directory, source_root,
        port.upstream_label,
    );
    if !compat_path_exists(tprint("%/%", package_source_directory, port.generated_entry))
        generator_error(tprint("configured generated entry was not emitted: %", port.generated_entry));

    module_source := tprint(
        "// Generated package entry point.\n#load \"src/%\";\n",
        port.generated_entry,
    );
    assert(File.write_entire_file(tprint("%/module.jai", package_directory), module_source));

    license_source := tprint("%/%", source_root, port.license_file);
    license_contents, license_ok := File.read_entire_file(license_source);
    if !license_ok generator_error(tprint("could not read upstream license: %", license_source));
    defer free(license_contents.data);
    assert(File.write_entire_file(tprint("%/LICENSE", package_directory), license_contents));

    generator_write_port_metadata(
        tprint("%/PORT.json", package_directory), port, provenance,
    );
}

generator_verify_package :: (
    root: string,
    port: *Port_Spec,
    package_directory: string,
    verification_directory: string,
) {
    assert(File.make_directory_if_it_does_not_exist(verification_directory, recursive = true));
    verification_name := tprint("%_module_verification", port.name);
    configured_verification_source := tprint("%/%", root, port.verification_file);
    verification_contents, verification_ok := File.read_entire_file(
        configured_verification_source,
    );
    if !verification_ok generator_error(tprint(
        "could not read module verification: %", configured_verification_source,
    ));
    defer free(verification_contents.data);
    verification_source := tprint(
        "%/%_verification.jai", verification_directory, port.name,
    );
    assert(File.write_entire_file(verification_source, verification_contents));
    verification_binary := tprint("%/%", verification_directory, verification_name);
    module_parent := compat_path_parent(package_directory);
    if !module_parent.has_value
        generator_error(tprint("module package has no parent directory: %", package_directory));
    generator_run_checked(
        string.[GENERATOR_JAI_EXECUTABLE, verification_source, "-quiet", "-output_path",
                verification_directory, "-exe", verification_name,
                "-import_dir", module_parent.value],
        root,
        tprint("compile % module verification", port.name),
    );
    generator_run_checked(
        string.[verification_binary], verification_directory,
        tprint("run % module verification", port.name),
    );
    print("Verified % module.\n", port.name);
}

generator_prepare_output_repository :: (
    root: string,
    port: *Port_Spec,
    offline: bool,
) -> string {
    output_repository := tprint("%/%", root, port.output_repository);
    if compat_path_exists(tprint("%/.git", output_repository))
        return output_repository;
    if compat_path_exists(output_repository)
        generator_error(tprint(
            "output path exists but is not a Git checkout: %", output_repository,
        ));
    if offline generator_error(tprint(
        "output checkout is missing for %; rerun without --offline", port.name,
    ));

    output_parent := compat_path_parent(output_repository);
    if !output_parent.has_value
        generator_error(tprint("output repository has no parent: %", output_repository));
    assert(File.make_directory_if_it_does_not_exist(output_parent.value, recursive = true));
    generator_run_checked(
        string.["git", "clone", port.output_url, output_repository],
        root,
        tprint("clone % output repository", port.name),
    );
    return output_repository;
}

generator_remove_stale_tracked_files :: (
    root: string,
    package_directory: string,
    output_repository: string,
) {
    tracked_output := generator_run_capture(
        string.["git", "-C", output_repository, "ls-files"],
        root,
        "list tracked output files",
    );
    defer port_owned_string_drop(*tracked_output);
    tracked_files := compat_string_split(tracked_output, "\n");
    defer array_free(tracked_files);
    for tracked_file: tracked_files {
        if !tracked_file.count continue;
        generator_require_managed_relative_path(tracked_file, "tracked output path");
        package_path := tprint("%/%", package_directory, tracked_file);
        if compat_path_exists(package_path) continue;
        output_path := tprint("%/%", output_repository, tracked_file);
        if compat_path_exists(output_path) && !File.file_delete(output_path)
            generator_error(tprint("could not remove stale generated file: %", output_path));
    }
}

generator_sync_package :: (
    root: string,
    port: *Port_Spec,
    package_directory: string,
) {
    output_repository := tprint("%/%", root, port.output_repository);
    if !compat_path_exists(tprint("%/.git", output_repository))
        generator_error(tprint("output repository is not initialized: %", output_repository));

    generator_remove_stale_tracked_files(
        root, package_directory, output_repository,
    );
    if !File_Utilities.copy_directory(package_directory, output_repository)
        generator_error(tprint("could not synchronize package into %", output_repository));
    print("Generated % into %.\n", port.name, port.output_repository);
}

generator_check_package :: (
    root: string,
    port: *Port_Spec,
    package_directory: string,
) {
    output_repository := tprint("%/%", root, port.output_repository);
    comparison := translator_process_run_output(
        string.["diff", "-ruN", "--exclude=.git", "--exclude=.build",
                package_directory, output_repository],
        root,
    );
    defer translator_process_output_result_deinit(*comparison);
    if comparison.process.type != .EXITED {
        if comparison.error.count write_string(comparison.error, to_standard_error = true);
        generator_error("could not compare generated package");
    }
    if comparison.process.exit_code == 0 {
        print("% is reproducible and up to date.\n", port.name);
        return;
    }
    if comparison.output.count write_string(comparison.output, to_standard_error = true);
    if comparison.error.count write_string(comparison.error, to_standard_error = true);
    if comparison.process.exit_code == 1
        generator_error(tprint("% differs from its reproducible package", port.output_repository));
    generator_error("diff failed while checking generated package");
}

generator_require_recorded_publish_metadata :: (
    root: string,
    port: *Port_Spec,
    output_repository: string,
) {
    metadata_path := tprint("%/PORT.json", output_repository);
    contents, ok := File.read_entire_file(metadata_path);
    if !ok generator_error(tprint(
        "% is missing; run the generator for % before publishing",
        metadata_path, port.name,
    ));
    defer free(contents.data);

    parsed := json_parse_with_result(contents);
    if !parsed.success generator_error(tprint(
        "% is invalid JSON at %:%: %",
        metadata_path, parsed.error.line, parsed.error.column,
        parsed.error.message,
    ));
    defer json_free(parsed.value);
    if json_get_int(parsed.value, "schema_version") != 2
        generator_error(tprint("% does not use PORT.json schema 2", metadata_path));

    upstream := json_get_object(parsed.value, "upstream");
    if upstream == null || json_get_string(upstream, "commit") != port.upstream_commit
        generator_error(tprint(
            "% does not record the configured upstream commit", metadata_path,
        ));

    generator := json_get_object(parsed.value, "generator");
    if generator == null generator_error(tprint(
        "% is missing generator provenance", metadata_path,
    ));
    recorded_commit := json_get(generator, "commit");
    if recorded_commit == null || recorded_commit.type != .STRING ||
       !recorded_commit.str.count
        generator_error(
            "PORT.json has no publishable generator commit; commit the inputs and regenerate",
        );
    head, has_head := generator_try_capture(
        string.["git", "-C", root, "rev-parse", "HEAD"], root,
    );
    defer port_owned_string_drop(*head);
    if !has_head || generator_trim_line_endings(head) != recorded_commit.str
        generator_error(
            "PORT.json generator commit does not match the current generator HEAD; regenerate first",
        );
}

generator_require_root_pushed :: (root: string) {
    upstream, has_upstream := generator_try_capture(
        string.[
            "git", "-C", root, "rev-parse", "--abbrev-ref",
            "--symbolic-full-name", "@{upstream}",
        ],
        root,
    );
    defer port_owned_string_drop(*upstream);
    if !has_upstream generator_error(
        "generator branch has no upstream; push it with --set-upstream first",
    );

    generator_run_checked(
        string.["git", "-C", root, "fetch", "--quiet", "--prune"],
        root,
        "fetch generator upstream",
    );
    head := generator_run_capture(
        string.["git", "-C", root, "rev-parse", "HEAD"],
        root,
        "read generator HEAD",
    );
    defer port_owned_string_drop(*head);
    remote_head := generator_run_capture(
        string.["git", "-C", root, "rev-parse", "@{upstream}"],
        root,
        "read generator upstream HEAD",
    );
    defer port_owned_string_drop(*remote_head);
    if generator_trim_line_endings(head) != generator_trim_line_endings(remote_head)
        generator_error(tprint(
            "generator HEAD must exactly match its pushed upstream %",
            generator_trim_line_endings(upstream),
        ));
}

generator_require_submodule_publishable :: (root: string, relative_path: string) {
    repository := tprint("%/%", root, relative_path);
    status := generator_run_capture(
        string.[
            "git", "-C", repository, "status", "--porcelain",
            "--untracked-files=all",
        ],
        root,
        tprint("inspect %", relative_path),
    );
    defer port_owned_string_drop(*status);
    if status.count generator_error(tprint(
        "% must be clean before publishing:\n%", relative_path, status,
    ));

    pinned := generator_run_capture(
        string.["git", "-C", root, "submodule", "status", "--", relative_path],
        root,
        tprint("inspect % gitlink", relative_path),
    );
    defer port_owned_string_drop(*pinned);
    if !pinned.count || pinned[0] != #char " "
        generator_error(tprint(
            "% must be checked out at the commit pinned by the generator",
            relative_path,
        ));

    generator_run_checked(
        string.["git", "-C", repository, "fetch", "--quiet", "--all", "--prune"],
        root,
        tprint("fetch % remotes", relative_path),
    );
    branches, on_remote_branch := generator_try_capture(
        string.["git", "-C", repository, "branch", "-r", "--contains", "HEAD"],
        root,
    );
    defer port_owned_string_drop(*branches);
    if !on_remote_branch || !generator_trim_line_endings(branches).count
        generator_error(tprint(
            "% HEAD is not reachable from a fetched remote branch",
            relative_path,
        ));
}

generator_require_publishable_inputs :: (
    root: string,
) -> Generator_Provenance {
    provenance := generator_read_provenance(root);
    if !provenance.has_commit {
        deinit(*provenance);
        generator_error("generator has no commit; commit and push its inputs first");
    }

    status := generator_generation_input_status(root);
    defer port_owned_string_drop(*status);
    if status.count {
        deinit(*provenance);
        generator_error(tprint(
            "generator inputs must be committed before publishing:\n%", status,
        ));
    }

    generator_require_root_pushed(root);
    for relative_path: GENERATOR_INPUT_SUBMODULES
        generator_require_submodule_publishable(root, relative_path);
    provenance.dirty = false;
    return provenance;
}

generator_require_inputs_unchanged :: (
    root: string,
    expected: *Generator_Provenance,
) {
    current := generator_read_provenance(root);
    defer deinit(*current);
    if !current.has_commit || current.dirty || current.commit != expected.commit
        generator_error(
            "generator inputs changed during publication; regenerate and retry",
        );
}

generator_require_output_current :: (root: string, output_repository: string) {
    upstream, has_upstream := generator_try_capture(
        string.[
            "git", "-C", output_repository, "rev-parse", "--abbrev-ref",
            "--symbolic-full-name", "@{upstream}",
        ],
        root,
    );
    defer port_owned_string_drop(*upstream);
    if !has_upstream generator_error(
        "output branch has no upstream; configure it before publishing",
    );
    generator_run_checked(
        string.["git", "-C", output_repository, "fetch", "--quiet", "--prune"],
        root,
        "fetch output upstream",
    );
    head := generator_run_capture(
        string.["git", "-C", output_repository, "rev-parse", "HEAD"],
        root,
        "read output HEAD",
    );
    defer port_owned_string_drop(*head);
    remote_head := generator_run_capture(
        string.["git", "-C", output_repository, "rev-parse", "@{upstream}"],
        root,
        "read output upstream HEAD",
    );
    defer port_owned_string_drop(*remote_head);
    if generator_trim_line_endings(head) != generator_trim_line_endings(remote_head)
        generator_error(tprint(
            "output HEAD must exactly match its upstream % before publishing",
            generator_trim_line_endings(upstream),
        ));
}

generator_commit_package :: (
    root: string,
    port: *Port_Spec,
    output_repository: string,
    provenance: *Generator_Provenance,
) {
    generator_run_checked(
        string.[
            "git", "-C", output_repository, "add", "-A", "--", ".",
            ":(exclude).build", ":(exclude).build/**",
        ],
        root,
        tprint("stage % output", port.name),
    );
    comparison := translator_process_run_output(
        string.["git", "-C", output_repository, "diff", "--cached", "--quiet"],
        root,
    );
    comparison_succeeded := generator_process_succeeded(*comparison);
    comparison_is_difference := comparison.process.type == .EXITED &&
        comparison.process.exit_code == 1;
    translator_process_output_result_deinit(*comparison);
    if comparison_succeeded {
        print("% already has the published generated tree.\n", port.name);
        return;
    }
    if !comparison_is_difference generator_error("could not inspect staged output changes");

    short_count := ifx port.upstream_commit.count < 7
        then port.upstream_commit.count else 7;
    short_revision := compat_string_slice(port.upstream_commit, 0, short_count);
    subject := tprint("feat: port %", short_revision);
    body := tprint(
        "Upstream-Commit: %\nGenerator-Commit: %",
        port.upstream_commit, provenance.commit,
    );
    generator_run_checked(
        string.["git", "-C", output_repository, "commit", "-m", subject, "-m", body],
        root,
        tprint("commit % output", port.name),
    );
    committed := generator_run_capture(
        string.["git", "-C", output_repository, "rev-parse", "HEAD"],
        root,
        tprint("read % output commit", port.name),
    );
    defer port_owned_string_drop(*committed);
    print(
        "Published % as local commit %\n",
        port.name, generator_trim_line_endings(committed),
    );
}

generator_build_package :: (
    root: string,
    port: *Port_Spec,
    options: Generator_Options,
    provenance: *Generator_Provenance,
) -> string {
    source_root := generator_prepare_upstream(root, port, options.offline);
    work_directory := tprint("%/.work/%", root, port.name);
    if compat_path_exists(work_directory) && !File.delete_directory(work_directory)
        generator_error(tprint("could not clear managed work directory: %", work_directory));
    assert(File.make_directory_if_it_does_not_exist(work_directory, recursive = true));

    compile_database := tprint("%/compile_commands.json", work_directory);
    transpiled_directory := tprint("%/transpiled", work_directory);
    package_directory := tprint("%/package/%", work_directory, port.name);
    verification_directory := tprint("%/verify", work_directory);
    generator_write_compile_database(compile_database, source_root, port);
    generator_transpile(root, port, compile_database, transpiled_directory);
    generator_assemble_package(
        root, port, source_root, transpiled_directory, package_directory,
        provenance,
    );
    generator_verify_package(root, port, package_directory, verification_directory);
    return package_directory;
}

generator_generate :: (port_name: string, options: Generator_Options) {
    port, found := generator_find_port(port_name);
    if !found generator_error(tprint("unknown port: %", port_name));
    root := generator_repository_root();
    generator_prepare_output_repository(root, *port, options.offline);
    provenance := generator_read_provenance(root);
    defer deinit(*provenance);
    package_directory := generator_build_package(root, *port, options, *provenance);
    generator_sync_package(root, *port, package_directory);
    if provenance.dirty {
        print("Generated development metadata cannot be published.\n");
        if !provenance.has_commit print("generator repository has no commit.\n");
        status := generator_generation_input_status(root);
        defer port_owned_string_drop(*status);
        if status.count print("Dirty generator inputs:\n%", status);
    }
}

generator_check :: (port_name: string, options: Generator_Options) {
    port, found := generator_find_port(port_name);
    if !found generator_error(tprint("unknown port: %", port_name));
    root := generator_repository_root();
    generator_prepare_output_repository(root, *port, options.offline);
    provenance := generator_read_provenance(root);
    defer deinit(*provenance);
    package_directory := generator_build_package(root, *port, options, *provenance);
    generator_check_package(root, *port, package_directory);
}

generator_publish :: (port_name: string, options: Generator_Options) {
    port, found := generator_find_port(port_name);
    if !found generator_error(tprint("unknown port: %", port_name));
    root := generator_repository_root();
    output_repository := generator_prepare_output_repository(
        root, *port, options.offline,
    );
    generator_require_recorded_publish_metadata(
        root, *port, output_repository,
    );
    provenance := generator_require_publishable_inputs(root);
    defer deinit(*provenance);
    generator_require_output_current(root, output_repository);

    package_directory := generator_build_package(
        root, *port, options, *provenance,
    );
    generator_sync_package(root, *port, package_directory);
    generator_check_package(root, *port, package_directory);
    generator_require_inputs_unchanged(root, *provenance);
    generator_commit_package(
        root, *port, output_repository, *provenance,
    );
}
