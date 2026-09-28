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
    environment_overrides: [] Translator_Process_Environment_Override = .[],
) {
    result := translator_process_run_output(arguments, working_directory, environment_overrides);
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
            ".gitmodules", "build.jai", "src", "ports",
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
    for port: generator_registered_ports() if port.name == name return port, true;
    return .{}, false;
}

generator_list_ports :: () {
    ports := generator_registered_ports();
    for *port: ports
        print("%\t%\n", port.name, port.upstream_commit);
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

generator_prepare_submodules :: (
    root: string, source_root: string,
    submodules: [] Port_Submodule_Spec, offline: bool,
) {
    for entry, index: submodules {
        generator_require_managed_relative_path(entry.path, "submodule path");
        generator_require_managed_relative_path(entry.license_file, "submodule license");
        if !entry.name.count generator_error("submodule name is empty");
        for other, other_index: submodules {
            if other_index >= index break;
            if other.path == entry.path || other.name == entry.name
                generator_error("duplicate submodule name or path");
        }
        link := generator_run_capture(
            string.["git", "-C", source_root, "ls-tree", "HEAD", "--", entry.path],
            root, "verify pinned submodule gitlink",
        );
        defer port_owned_string_drop(*link);
        expected := tprint("160000 commit %\t%", entry.upstream_commit, entry.path);
        if generator_trim_line_endings(link) != expected
            generator_error(tprint("submodule % does not match its pinned gitlink", entry.path));
        for field: string.["path", "url"] {
            value := generator_run_capture(
                string.["git", "-C", source_root, "config", "--file", ".gitmodules",
                        "--get", tprint("submodule.%.%", entry.name, field)],
                root, "verify pinned submodule configuration",
            );
            defer port_owned_string_drop(*value);
            wanted := ifx field == "path" then entry.path else entry.upstream_url;
            if generator_trim_line_endings(value) != wanted
                generator_error(tprint("submodule % % does not match its recipe", entry.name, field));
        }
        checkout := tprint("%/%", source_root, entry.path);
        if !compat_path_exists(tprint("%/.git", checkout)) {
            if offline generator_error(tprint("pinned submodule is missing: %; rerun without --offline", entry.path));
            // Explicit checkout ignores custom update strategies. Git uses the
            // pinned gitlink; no branch or unpinned HEAD is requested.
            generator_run_checked(
                string.["git", "-c", tprint("submodule.%.url=%", entry.name, entry.upstream_url),
                        "-C", source_root, "submodule", "update", "--init",
                        "--checkout", "--", entry.path], root,
                tprint("prepare pinned submodule %", entry.path),
            );
        }
        revision := generator_run_capture(
            string.["git", "-C", checkout, "rev-parse", "HEAD"], root,
            "verify submodule revision",
        );
        defer port_owned_string_drop(*revision);
        if generator_trim_line_endings(revision) != entry.upstream_commit
            generator_error(tprint("submodule % has the wrong revision", entry.path));
        status := generator_run_capture(
            string.["git", "-C", checkout, "status", "--porcelain", "--untracked-files=all"],
            root, "verify clean submodule checkout",
        );
        defer port_owned_string_drop(*status);
        if status.count generator_error(tprint("managed submodule checkout is dirty: %\n%", checkout, status));
    }
}

generator_resolve_source_path :: (
    source_root: string, port: *Port_Spec, relative_path: string,
) -> string {
    if relative_path.count && relative_path[0] == #char "@" {
        separator := 1;
        while separator < relative_path.count && relative_path[separator] != #char "/"
            separator += 1;
        name := compat_string_slice(relative_path, 1, separator);
        for dependency: port.dependencies if dependency.name == name {
            parent := compat_path_parent(source_root);
            assert(parent.has_value);
            if separator == relative_path.count return tprint("%/%", parent.value, name);
            path := compat_string_slice(relative_path, separator + 1, relative_path.count);
            generator_require_managed_relative_path(path, "dependency source path");
            return tprint("%/%/%", parent.value, name, path);
        }
        generator_error(tprint("% references undeclared dependency: %", port.name, name));
    }
    generator_require_managed_relative_path(relative_path, "source/include path");
    return tprint("%/%", source_root, relative_path);
}

generator_write_compile_database :: (
    path: string,
    source_root: string,
    port: *Port_Spec,
    module: *Port_Module_Spec,
    prepared_include_directory: string = "",
) {
    builder: String_Builder;
    append(*builder, "[\n");
    source_paths: [..] string;
    defer array_free(source_paths);
    source_groups: [..] *Port_Source_Group_Spec;
    defer array_free(source_groups);
    for source_file: module.source_files {
        array_add(*source_paths, generator_resolve_source_path(source_root, port, source_file));
        array_add(*source_groups, null);
    }
    for source_file: module.generator_source_files {
        generator_require_managed_relative_path(source_file, "generator source file");
        array_add(*source_paths, tprint("%/%", generator_repository_root(), source_file));
        array_add(*source_groups, null);
    }
    for *group: module.source_groups for source_file: group.source_files {
        array_add(*source_paths, generator_resolve_source_path(source_root, port, source_file));
        array_add(*source_groups, group);
    }
    for source_path, source_index: source_paths {
        if !compat_path_exists(source_path)
            generator_error(tprint("configured source file does not exist: %", source_path));

        arguments: [..] string;
        array_add(*arguments, ifx port.language == .C then "clang" else "clang++");
        array_add(*arguments, tprint("-std=%", port.standard));
        if prepared_include_directory.count
            array_add(*arguments, tprint("-I%", prepared_include_directory));
        for flag: port.compiler_flags array_add(*arguments, flag);
        for flag: module.compiler_flags array_add(*arguments, flag);
        for define: module.defines array_add(*arguments, tprint("-D%", define));
        group := source_groups[source_index];
        if group {
            for flag: group.compiler_flags array_add(*arguments, flag);
            for define: group.defines array_add(*arguments, tprint("-D%", define));
            for include_directory: group.include_directories
                array_add(*arguments, tprint("-I%", generator_resolve_source_path(source_root, port, include_directory)));
        }
        for include_directory: port.include_directories {
            include_path := generator_resolve_source_path(source_root, port, include_directory);
            array_add(*arguments, tprint("-I%", include_path));
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
        if source_index + 1 < source_paths.count append(*builder, #char ",");
        append(*builder, #char "\n");
        array_free(arguments);
    }
    append(*builder, "]\n");
    assert(File.write_entire_file(path, *builder));
}

generator_prepare_cmake :: (
    root: string, source_root: string, work_directory: string, preparation: *Port_CMake_Spec,
    link_targets: [] string = string.[],
    port: *Port_Spec = null,
) -> string {
    directory := tprint("%/cmake", work_directory);
    configured_source := source_root;
    if preparation.source_directory.count {
        generator_require_managed_relative_path(preparation.source_directory, "CMake source directory");
        configured_source = tprint("%/%", source_root, preparation.source_directory);
    }
    generator_prepare_cmake_system_links(directory, link_targets);
    arguments: [..] string;
    defer array_free(arguments);
    array_add(*arguments, "cmake", "-S", configured_source, "-B", directory, "-G", "Ninja",
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON", "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_C_COMPILER=clang", "-DCMAKE_CXX_COMPILER=clang++");
    array_add(*arguments, tprint("-DCMAKE_PROJECT_INCLUDE=%/generator_system_links.cmake", directory));
    for variable: preparation.cache_variables {
        separator := compat_string_find(variable, "=");
        if separator <= 0 generator_error(tprint("CMake cache variable must use KEY=VALUE: %", variable));
        key := compat_string_slice(variable, 0, separator);
        if key == "CMAKE_EXPORT_COMPILE_COMMANDS" || key == "CMAKE_C_COMPILER" ||
           key == "CMAKE_CXX_COMPILER" || key == "CMAKE_GENERATOR" || key == "CMAKE_PROJECT_INCLUDE"
            generator_error(tprint("CMake preparation reserves cache variable %", key));
        for byte: key if !((byte >= #char "A" && byte <= #char "Z") ||
                          (byte >= #char "a" && byte <= #char "z") ||
                          (byte >= #char "0" && byte <= #char "9") || byte == #char "_")
            generator_error(tprint("invalid CMake cache variable key: %", key));
        array_add(*arguments, tprint("-D%", variable));
    }
    for variable: preparation.source_cache_variables {
        if port == null generator_error("CMake source cache mappings require a port specification");
        if !variable.key.count generator_error("CMake source cache key cannot be empty");
        for byte: variable.key if !((byte >= #char "A" && byte <= #char "Z") ||
                                   (byte >= #char "a" && byte <= #char "z") ||
                                   (byte >= #char "0" && byte <= #char "9") || byte == #char "_")
            generator_error(tprint("invalid CMake source cache variable key: %", variable.key));
        if variable.key == "CMAKE_EXPORT_COMPILE_COMMANDS" || variable.key == "CMAKE_C_COMPILER" ||
           variable.key == "CMAKE_CXX_COMPILER" || variable.key == "CMAKE_GENERATOR" ||
           variable.key == "CMAKE_PROJECT_INCLUDE"
            generator_error(tprint("CMake preparation reserves cache variable %", variable.key));
        source := generator_resolve_source_path(source_root, port, variable.source);
        if !compat_path_exists(source) generator_error(tprint("CMake source cache path does not exist: %", source));
        array_add(*arguments, tprint("-D%=%", variable.key, source));
    }
    generator_run_checked(arguments, root, "configure pinned upstream source");
    if preparation.build_targets.count {
        arguments.count = 0;
        array_add(*arguments, "cmake", "--build", directory, "--parallel", "1", "--target");
        for target: preparation.build_targets {
            generator_require_managed_relative_path(target, "CMake preparation target");
            if target == "all" || target == "install" || target == "clean"
                generator_error(tprint("CMake preparation requires an explicit generated target: %", target));
            array_add(*arguments, target);
        }
        generator_run_checked(arguments, root, "generate upstream build headers");
    }
    return directory;
}

generator_write_cmake_compile_database :: (
    path: string, cmake_directory: string, targets: [] string,
) {
    generator_write_cmake_compile_database_native(
        path, tprint("%/compile_commands.json", cmake_directory), targets,
    );
}

generator_prepare_make :: (root: string, source_root: string, work_directory: string, port: *Port_Spec) -> string {
    preparation := *port.make;
    directory := tprint("%/make", work_directory);
    script := generator_resolve_source_path(source_root, port, preparation.configure_script);
    for target: preparation.generated_targets {
        generator_require_managed_relative_path(target, "Make generated target");
    }
    generator_prepare_make_native(
        directory, script, preparation.configure_arguments,
        preparation.variables, preparation.generated_targets,
    );
    return directory;
}

generator_write_make_compile_database :: (root: string, path: string, directory: string, port: *Port_Spec, module: *Port_Module_Spec) {
    for target: module.make_targets {
        generator_require_managed_relative_path(target, "Make source target");
    }
    generator_write_make_compile_database_native(
        path, directory, port.make.variables, module.make_targets,
    );
}

generator_transpile :: (
    root: string,
    port: *Port_Spec,
    module: *Port_Module_Spec,
    compile_database: string,
    output_directory: string,
    prepared_include_directory: string = "",
    system_libraries_manifest: string = "",
) {
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
    config.module_name = port_optional_some(copy_string(module.transpiler_prefix));
    config.output_directory = port_optional_some(copy_string(output_directory));
    if system_libraries_manifest.count
        config.system_libraries_manifest = port_optional_some(copy_string(system_libraries_manifest));
    additional_flags: [..] string;
    defer array_free(additional_flags);
    if module.cmake_targets.count {
        if prepared_include_directory.count
            array_add(*additional_flags, tprint("-I%", prepared_include_directory));
        for flag: port.compiler_flags array_add(*additional_flags, flag);
        for flag: module.compiler_flags array_add(*additional_flags, flag);
        for define: module.defines array_add(*additional_flags, tprint("-D%", define));
    }
    cpp_transpiler_run(config, compile_database, additional_flags);
}

Generator_Copy_Arguments :: struct {
    destination: string;
    source_root: string;
    upstream_label: string;
    dependencies: [] Port_Dependency_Spec;
    copied_count: int;
}

generator_copy_transpiled_output :: (
    transpiled_source_directory: string,
    generated_destination: string,
    source_root: string,
    upstream_label: string,
    dependencies: [] Port_Dependency_Spec,
) {
    args := Generator_Copy_Arguments.{
        destination = generated_destination,
        source_root = source_root,
        upstream_label = upstream_label,
        dependencies = dependencies,
    };
    visitor :: (info: *File_Utilities.File_Visit_Info, args: *Generator_Copy_Arguments) {
        if info.is_directory || !generator_string_ends_with(info.short_name, ".jai") return;
        contents, ok := File.read_entire_file(info.full_name);
        if !ok generator_error(tprint("could not read transpiler output: %", info.full_name));
        defer free(contents.data);
        path_normalized := cpp_jai_replace_all(contents, args.source_root, args.upstream_label);
        defer port_owned_string_drop(*path_normalized);
        parent := compat_path_parent(args.source_root);
        assert(parent.has_value);
        for dependency: args.dependencies {
            replaced := cpp_jai_replace_all(
                path_normalized, tprint("%/%", parent.value, dependency.name), dependency.upstream_label,
            );
            port_owned_string_drop(*path_normalized);
            path_normalized = replaced;
        }
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
    append(*builder, "{\n  \"schema_version\": 3,\n  \"name\": ");
    generator_json_append_string(*builder, port.name);
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
    append(*builder, ",\n  \"language\": ");
    generator_json_append_string(
        *builder, ifx port.language == .C then "c" else "c++",
    );
    append(*builder, ",\n  \"standard\": ");
    generator_json_append_string(*builder, port.standard);
    append(*builder, ",\n  \"supported_target\": ");
    generator_json_append_string(*builder, port.supported_target);
    append(*builder, ",\n  \"include_directories\": ");
    generator_json_append_array(*builder, port.include_directories, "    ");
    append(*builder, ",\n  \"compiler_flags\": ");
    generator_json_append_array(*builder, port.compiler_flags, "    ");
    append(*builder, ",\n  \"cmake\": {\"enabled\": ");
    append(*builder, ifx port.cmake.enabled then "true" else "false");
    append(*builder, ", \"source_directory\": ");
    generator_json_append_string(*builder, port.cmake.source_directory);
    append(*builder, ", \"cache_variables\": ");
    generator_json_append_array(*builder, port.cmake.cache_variables, "      ");
    append(*builder, ", \"source_cache_variables\": [");
    for variable, index: port.cmake.source_cache_variables {
        if index append(*builder, ",");
        append(*builder, "{\"key\": ");
        generator_json_append_string(*builder, variable.key);
        append(*builder, ", \"source\": ");
        generator_json_append_string(*builder, variable.source);
        append(*builder, "}");
    }
    append(*builder, "]");
    append(*builder, ", \"build_targets\": ");
    generator_json_append_array(*builder, port.cmake.build_targets, "      ");
    append(*builder, "}");
    append(*builder, ",\n  \"make\": {\"enabled\": ");
    append(*builder, ifx port.make.enabled then "true" else "false");
    append(*builder, ", \"configure_script\": ");
    generator_json_append_string(*builder, port.make.configure_script);
    append(*builder, ", \"configure_arguments\": ");
    generator_json_append_array(*builder, port.make.configure_arguments, "      ");
    append(*builder, ", \"variables\": ");
    generator_json_append_array(*builder, port.make.variables, "      ");
    append(*builder, ", \"generated_targets\": ");
    generator_json_append_array(*builder, port.make.generated_targets, "      ");
    append(*builder, "}");
    append(*builder, ",\n  \"prepared_files\": [");
    for prepared, index: port.prepared_files {
        if index append(*builder, ",");
        append(*builder, "\n    {\"source\": ");
        generator_json_append_string(*builder, prepared.source);
        append(*builder, ", \"destination\": ");
        generator_json_append_string(*builder, prepared.destination);
        append(*builder, "}");
    }
    append(*builder, "\n  ]");
    append(*builder, ",\n  \"dependencies\": [");
    for dependency, index: port.dependencies {
        if index append(*builder, ",");
        append(*builder, "\n    {\"name\": ");
        generator_json_append_string(*builder, dependency.name);
        append(*builder, ", \"url\": ");
        generator_json_append_string(*builder, dependency.upstream_url);
        append(*builder, ", \"commit\": ");
        generator_json_append_string(*builder, dependency.upstream_commit);
        append(*builder, "}");
    }
    append(*builder, "\n  ]");
    append(*builder, ",\n  \"submodules\": [");
    for entry, index: port.submodules {
        if index append(*builder, ",");
        append(*builder, "\n    {\"path\": ");
        generator_json_append_string(*builder, entry.path);
        append(*builder, ", \"url\": ");
        generator_json_append_string(*builder, entry.upstream_url);
        append(*builder, ", \"commit\": ");
        generator_json_append_string(*builder, entry.upstream_commit);
        append(*builder, "}");
    }
    append(*builder, "\n  ]");
    append(*builder, ",\n  \"modules\": [\n");
    for *module, module_index: port.modules {
        append(*builder, "    {\n      \"path\": ");
        generator_json_append_string(*builder, module.output_path);
        append(*builder, ",\n      \"transpiler_prefix\": ");
        generator_json_append_string(*builder, module.transpiler_prefix);
        append(*builder, ",\n      \"sources\": ");
        generator_json_append_array(*builder, module.source_files, "        ");
        append(*builder, ",\n      \"generator_sources\": [");
        for source_file, source_index: module.generator_source_files {
            generator_require_managed_relative_path(source_file, "generator source file");
            root := generator_repository_root();
            digest := generator_run_capture(string.["sha256sum", "--", tprint("%/%", root, source_file)],
                root, "hash concrete generator source");
            defer port_owned_string_drop(*digest);
            if digest.count < 64 generator_error("invalid source SHA256 result");
            if source_index append(*builder, ",");
            append(*builder, "{\"path\": ");
            generator_json_append_string(*builder, source_file);
            append(*builder, ", \"sha256\": ");
            generator_json_append_string(*builder, compat_string_slice(digest, 0, 64));
            append(*builder, "}");
        }
        append(*builder, "]");
        append(*builder, ",\n      \"source_groups\": [");
        for group, group_index: module.source_groups {
            if group_index append(*builder, ",");
            append(*builder, "{\"sources\": ");
            generator_json_append_array(*builder, group.source_files, "        ");
            append(*builder, ", \"include_directories\": ");
            generator_json_append_array(*builder, group.include_directories, "        ");
            append(*builder, ", \"defines\": ");
            generator_json_append_array(*builder, group.defines, "        ");
            append(*builder, ", \"compiler_flags\": ");
            generator_json_append_array(*builder, group.compiler_flags, "        ");
            append(*builder, "}");
        }
        append(*builder, "]");
        append(*builder, ",\n      \"cmake_targets\": ");
        generator_json_append_array(*builder, module.cmake_targets, "        ");
        append(*builder, ",\n      \"make_targets\": ");
        generator_json_append_array(*builder, module.make_targets, "        ");
        append(*builder, ",\n      \"defines\": ");
        generator_json_append_array(*builder, module.defines, "        ");
        append(*builder, ",\n      \"compiler_flags\": ");
        generator_json_append_array(*builder, module.compiler_flags, "        ");
        append(*builder, ",\n      \"system_libraries\": ");
        generator_json_append_array(*builder, module.system_libraries, "        ");
        append(*builder, ",\n      \"entry\": ");
        generator_json_append_string(*builder, module.generated_entry);
        append(*builder, "\n    }");
        if module_index + 1 < port.modules.count append(*builder, #char ",");
        append(*builder, #char "\n");
    }
    append(*builder, "  ]");
    append(*builder, "\n}\n");
    assert(File.write_entire_file(path, *builder));
}

generator_assemble_module :: (
    port: *Port_Spec,
    module: *Port_Module_Spec,
    source_root: string,
    transpiled_directory: string,
    module_directory: string,
) {
    module_source_directory := tprint("%/src", module_directory);
    assert(File.make_directory_if_it_does_not_exist(module_source_directory, recursive = true));

    transpiled_source_directory := tprint("%/src", transpiled_directory);
    generator_copy_transpiled_output(
        transpiled_source_directory, module_source_directory, source_root,
        port.upstream_label, port.dependencies,
    );
    if !compat_path_exists(tprint("%/%", module_source_directory, module.generated_entry))
        generator_error(tprint(
            "configured generated entry was not emitted for %: %",
            module.transpiler_prefix, module.generated_entry,
        ));

    module_source := tprint(
        "// Generated package entry point.\n#load \"src/%\";\n",
        module.generated_entry,
    );
    assert(File.write_entire_file(tprint("%/module.jai", module_directory), module_source));
}

generator_assemble_package_files :: (
    port: *Port_Spec,
    source_root: string,
    package_directory: string,
    provenance: *Generator_Provenance,
) {
    assert(File.make_directory_if_it_does_not_exist(package_directory, recursive = true));

    license_source := tprint("%/%", source_root, port.license_file);
    license_contents, license_ok := File.read_entire_file(license_source);
    if !license_ok generator_error(tprint("could not read upstream license: %", license_source));
    defer free(license_contents.data);
    assert(File.write_entire_file(tprint("%/LICENSE", package_directory), license_contents));
    parent := compat_path_parent(source_root);
    assert(parent.has_value);
    for dependency: port.dependencies {
        path := tprint("%/%/%", parent.value, dependency.name, dependency.license_file);
        contents, ok := File.read_entire_file(path);
        if !ok generator_error(tprint("could not read dependency license: %", path));
        defer free(contents.data);
        assert(File.write_entire_file(tprint("%/LICENSE-%", package_directory, dependency.name), contents));
    }
    for entry, index: port.submodules {
        path := tprint("%/%/%", source_root, entry.path, entry.license_file);
        contents, ok := File.read_entire_file(path);
        if !ok generator_error(tprint("could not read submodule license: %", path));
        defer free(contents.data);
        assert(File.write_entire_file(tprint("%/LICENSE-submodule-%", package_directory, index), contents));
    }

    generator_write_port_metadata(
        tprint("%/PORT.json", package_directory), port, provenance,
    );
}

generator_test_module :: (
    root: string,
    port: *Port_Spec,
    module: *Port_Module_Spec,
    package_directory: string,
    test_directory: string,
    library_manifest: string,
) {
    assert(File.make_directory_if_it_does_not_exist(test_directory, recursive = true));
    test_name := tprint(
        "%_%_module_test", port.name, module.transpiler_prefix,
    );
    configured_test_source := ifx module.output_path.count
        then tprint("%/ports/%/%/test.jai", root, port.name, module.output_path)
        else tprint("%/ports/%/test.jai", root, port.name);
    test_contents, test_ok := File.read_entire_file(
        configured_test_source,
    );
    if !test_ok generator_error(tprint(
        "could not read module test: %", configured_test_source,
    ));
    defer free(test_contents.data);
    test_source := tprint(
        "%/%_%_test.jai",
        test_directory, port.name, module.transpiler_prefix,
    );
    assert(File.write_entire_file(test_source, test_contents));
    test_binary := tprint("%/%", test_directory, test_name);
    module_parent := compat_path_parent(package_directory);
    if !module_parent.has_value
        generator_error(tprint("module package has no parent directory: %", package_directory));
    test_environment := generator_test_environment(library_manifest);
    defer generator_test_environment_deinit(*test_environment);
    launch: [..] string;
    defer array_free(launch);
    array_add(*launch, GENERATOR_JAI_EXECUTABLE, test_source, "-quiet", "-output_path",
        test_directory, "-exe", test_name, "-import_dir", module_parent.value);
    generator_run_checked(
        launch,
        root,
        tprint("compile %/% module test", port.name, module.transpiler_prefix),
        test_environment,
    );
    launch.count = 0;
    array_add(*launch, test_binary);
    generator_run_checked(
        launch, test_directory,
        tprint("run %/% module test", port.name, module.transpiler_prefix),
        test_environment,
    );
    if module.output_path.count
        print("Tested %/% module.\n", port.name, module.output_path);
    else print("Tested % module.\n", port.name);
}

generator_output_repository_relative :: (port: *Port_Spec) -> string {
    return tprint("out/%", port.name);
}

generator_output_repository_path :: (root: string, port: *Port_Spec) -> string {
    return tprint("%/out/%", root, port.name);
}

generator_prepare_output_repository :: (
    root: string,
    port: *Port_Spec,
    offline: bool,
) -> string {
    output_repository := generator_output_repository_path(root, port);
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
    output_repository := generator_output_repository_path(root, port);
    if !compat_path_exists(tprint("%/.git", output_repository))
        generator_error(tprint("output repository is not initialized: %", output_repository));

    generator_remove_stale_tracked_files(
        root, package_directory, output_repository,
    );
    if !File_Utilities.copy_directory(package_directory, output_repository)
        generator_error(tprint("could not synchronize package into %", output_repository));
    print("Generated % into %.\n", port.name, generator_output_repository_relative(port));
}

generator_check_package :: (
    root: string,
    port: *Port_Spec,
    package_directory: string,
) {
    output_repository := generator_output_repository_path(root, port);
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
        generator_error(tprint(
            "% differs from its reproducible package",
            generator_output_repository_relative(port),
        ));
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
    if json_get_int(parsed.value, "schema_version") != 3
        generator_error(tprint("% does not use PORT.json schema 3", metadata_path));

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

generator_require_output_current :: (
    root: string,
    output_repository: string,
) -> bool {
    generator_run_checked(
        string.["git", "-C", output_repository, "fetch", "--quiet", "--prune"],
        root,
        "fetch output upstream",
    );

    head, has_head := generator_try_capture(
        string.["git", "-C", output_repository, "rev-parse", "--verify", "HEAD"],
        root,
    );
    defer port_owned_string_drop(*head);
    if !has_head {
        remote_heads := generator_run_capture(
            string.["git", "-C", output_repository, "ls-remote", "--heads", "origin"],
            root,
            "inspect empty output remote",
        );
        defer port_owned_string_drop(*remote_heads);
        if generator_trim_line_endings(remote_heads).count
            generator_error(
                "output repository has no local commit, but origin has branches; check out its default branch first",
            );

        branch, has_branch := generator_try_capture(
            string.["git", "-C", output_repository, "symbolic-ref", "--quiet", "--short", "HEAD"],
            root,
        );
        defer port_owned_string_drop(*branch);
        if !has_branch || !generator_trim_line_endings(branch).count
            generator_error("empty output repository has no branch for its initial commit");
        return true;
    }

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
    return false;
}

generator_commit_package :: (
    root: string,
    port: *Port_Spec,
    output_repository: string,
    provenance: *Generator_Provenance,
    initial_publication: bool,
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
    if initial_publication {
        branch := generator_run_capture(
            string.[
                "git", "-C", output_repository, "symbolic-ref", "--quiet",
                "--short", "HEAD",
            ],
            root,
            tprint("read % output branch", port.name),
        );
        defer port_owned_string_drop(*branch);
        print(
            "First publication: push it and configure its upstream with:\n  git -C % push --set-upstream origin %\n",
            generator_output_repository_relative(port), generator_trim_line_endings(branch),
        );
    }
}

generator_build_package :: (
    root: string,
    port: *Port_Spec,
    options: Generator_Options,
    provenance: *Generator_Provenance,
) -> string {
    if !port.modules.count generator_error(tprint("% defines no modules", port.name));
    for *module, module_index: port.modules {
        if module.output_path.count
            generator_require_managed_relative_path(module.output_path, "module output path");
        if !module.transpiler_prefix.count generator_error(tprint(
            "% module % has no transpiler prefix", port.name, module_index,
        ));
        explicit_sources := module.source_files.count + module.generator_source_files.count;
        for group: module.source_groups explicit_sources += group.source_files.count;
        if !explicit_sources && !module.cmake_targets.count && !module.make_targets.count generator_error(tprint(
            "% module % has no source files", port.name, module.transpiler_prefix,
        ));
        if (explicit_sources && (module.cmake_targets.count || module.make_targets.count)) ||
           (module.cmake_targets.count && module.make_targets.count)
            generator_error("a module must select exactly one of explicit sources, CMake or Make targets");
        if module.cmake_targets.count && !port.cmake.enabled
            generator_error("CMake target selection requires CMake preparation");
        if module.make_targets.count && !port.make.enabled
            generator_error("Make target selection requires Make preparation");
        generator_require_managed_relative_path(module.generated_entry, "generated entry");
        for *other, other_index: port.modules {
            if other_index >= module_index break;
            if other.output_path == module.output_path generator_error(tprint(
                "% has duplicate module output path: %", port.name, module.output_path,
            ));
        }
    }

    source_root := generator_prepare_upstream(root, port, options.offline);
    generator_prepare_submodules(root, source_root, port.submodules, options.offline);
    for dependency, index: port.dependencies {
        generator_require_managed_relative_path(dependency.name, "dependency name");
        for byte: dependency.name if byte == #char "/"
            generator_error("dependency names must be single path components");
        if dependency.name == port.name generator_error("dependency name equals the port name");
        for other, other_index: port.dependencies {
            if other_index >= index break;
            if other.name == dependency.name generator_error("duplicate dependency name");
        }
        generator_require_managed_relative_path(dependency.license_file, "dependency license");
        dependency_port := Port_Spec.{
            name = dependency.name,
            upstream_url = dependency.upstream_url,
            upstream_commit = dependency.upstream_commit,
        };
        generator_prepare_upstream(root, *dependency_port, options.offline);
    }
    work_directory := tprint("%/.work/%", root, port.name);
    if compat_path_exists(work_directory) && !File.delete_directory(work_directory)
        generator_error(tprint("could not clear managed work directory: %", work_directory));
    assert(File.make_directory_if_it_does_not_exist(work_directory, recursive = true));
    prepared_include_directory := "";
    if port.prepared_files.count {
        prepared_include_directory = tprint("%/include", work_directory);
        for prepared, index: port.prepared_files {
            generator_require_managed_relative_path(prepared.destination, "prepared header destination");
            for other, other_index: port.prepared_files {
                if other_index >= index break;
                if other.destination == prepared.destination generator_error("duplicate prepared header destination");
            }
            source := generator_resolve_source_path(source_root, port, prepared.source);
            contents, ok := File.read_entire_file(source);
            if !ok generator_error(tprint("could not read prepared header source: %", source));
            defer free(contents.data);
            destination := tprint("%/%", prepared_include_directory, prepared.destination);
            parent := compat_path_parent(destination);
            assert(parent.has_value);
            assert(File.make_directory_if_it_does_not_exist(parent.value, recursive = true));
            if !File.write_entire_file(destination, contents)
                generator_error(tprint("could not write prepared header: %", destination));
        }
    }

    cmake_directory := "";
    link_targets: [..] string;
    defer array_free(link_targets);
    for module: port.modules for target: module.cmake_targets {
        duplicate := false;
        for existing: link_targets if existing == target { duplicate = true; break; }
        if !duplicate array_add(*link_targets, target);
    }
    if port.cmake.enabled cmake_directory = generator_prepare_cmake(
        root, source_root, work_directory, *port.cmake, link_targets, port,
    );
    if port.cmake.enabled && port.make.enabled generator_error("a port cannot configure both CMake and Make");
    make_directory := "";
    if port.make.enabled make_directory = generator_prepare_make(root, source_root, work_directory, port);
    package_directory := tprint("%/package/%", work_directory, port.name);
    for *module: port.modules {
        work_name := ifx module.output_path.count
            then module.output_path else "_root";
        module_work_directory := tprint("%/modules/%", work_directory, work_name);
        assert(File.make_directory_if_it_does_not_exist(
            module_work_directory, recursive = true,
        ));
        compile_database := tprint("%/compile_commands.json", module_work_directory);
        transpiled_directory := tprint("%/transpiled", module_work_directory);
        module_directory := ifx module.output_path.count
            then tprint("%/%", package_directory, module.output_path)
            else package_directory;
        if module.cmake_targets.count generator_write_cmake_compile_database(
            compile_database, cmake_directory, module.cmake_targets,
        );
        else if module.make_targets.count generator_write_make_compile_database(
            root, compile_database, make_directory, port, module,
        );
        else generator_write_compile_database(
            compile_database, source_root, port, module, prepared_include_directory,
        );
        system_manifest := tprint("%/system-libraries.json", module_work_directory);
        generator_resolve_system_libraries_native(
            system_manifest, module.system_libraries,
            ifx module.cmake_targets.count then cmake_directory else "",
            module.cmake_targets,
        );
        generator_transpile(root, port, module, compile_database, transpiled_directory,
            prepared_include_directory, system_manifest);
        generator_assemble_module(
            port, module, source_root, transpiled_directory, module_directory,
        );
    }

    generator_assemble_package_files(
        port, source_root, package_directory, provenance,
    );
    for *module: port.modules {
        work_name := ifx module.output_path.count
            then module.output_path else "_root";
        test_directory := tprint("%/test/%", work_directory, work_name);
        generator_test_module(
            root, port, module, package_directory, test_directory,
            tprint("%/modules/%/system-libraries.json", work_directory, work_name),
        );
    }
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

// Validate a new recipe without requiring a published output repository.
generator_validate :: (port_name: string, options: Generator_Options) {
    port, found := generator_find_port(port_name);
    if !found generator_error(tprint("unknown port: %", port_name));
    root := generator_repository_root();
    provenance := generator_read_provenance(root);
    defer deinit(*provenance);
    package_directory := generator_build_package(root, *port, options, *provenance);
    print("Validated % recipe. Package: %\n", port.name, package_directory);
    print("Recipe tests do not establish full parity or performance; use differential checks for those.\n");
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
    initial_publication := generator_require_output_current(root, output_repository);

    package_directory := generator_build_package(
        root, *port, options, *provenance,
    );
    generator_sync_package(root, *port, package_directory);
    generator_check_package(root, *port, package_directory);
    generator_require_inputs_unchanged(root, *provenance);
    generator_commit_package(
        root, *port, output_repository, *provenance, initial_publication,
    );
}
