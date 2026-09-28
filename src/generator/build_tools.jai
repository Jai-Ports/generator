Generator_Shell_Words :: struct {
    values: [..] string;
    valid: bool;
}

deinit :: (words: *Generator_Shell_Words) {
    if words == null return;
    for *value: words.values port_owned_string_drop(value);
    array_free(words.values);
    words.* = .{};
}

generator_shell_words :: (text: string) -> Generator_Shell_Words {
    result: Generator_Shell_Words;
    result.valid = true;
    token: String_Builder;
    token_started := false;
    quote: u8;
    cursor := 0;

    flush_token :: () #expand {
        if token_started {
            array_add(*result.values, builder_to_string(*token));
            token = .{};
            token_started = false;
        }
    }

    while cursor < text.count {
        byte := text[cursor];
        if quote == 0 {
            if compat_ascii_is_whitespace(byte) {
                flush_token();
                cursor += 1;
                continue;
            }
            if byte == #char "'" || byte == #char "\"" {
                quote = byte;
                token_started = true;
                cursor += 1;
                continue;
            }
            if byte == #char "\\" {
                cursor += 1;
                if cursor >= text.count { result.valid = false; break; }
                append(*token, text[cursor]);
                token_started = true;
                cursor += 1;
                continue;
            }
            append(*token, byte);
            token_started = true;
            cursor += 1;
            continue;
        }

        if byte == quote {
            quote = 0;
            cursor += 1;
            continue;
        }
        if quote == #char "\"" && byte == #char "\\" {
            cursor += 1;
            if cursor >= text.count { result.valid = false; break; }
            append(*token, text[cursor]);
            token_started = true;
            cursor += 1;
            continue;
        }
        append(*token, byte);
        token_started = true;
        cursor += 1;
    }
    if quote != 0 result.valid = false;
    if result.valid flush_token();
    return result;
}

generator_string_array_contains :: (values: [] string, wanted: string) -> bool {
    for value: values if value == wanted return true;
    return false;
}

generator_path_file_name :: (path: string) -> string {
    value := compat_path_file_name(path);
    if value.has_value return value.value;
    return path;
}

generator_path_extension :: (path: string) -> string {
    name := generator_path_file_name(path);
    cursor := name.count;
    while cursor > 0 {
        cursor -= 1;
        if name[cursor] == #char "." return compat_string_slice(name, cursor, name.count);
    }
    return "";
}

generator_ascii_lower :: (byte: u8) -> u8 {
    if byte >= #char "A" && byte <= #char "Z" return byte + (#char "a" - #char "A");
    return byte;
}

generator_string_equals_ascii_case_insensitive :: (left: string, right: string) -> bool {
    if left.count != right.count return false;
    for byte, index: left if generator_ascii_lower(byte) != generator_ascii_lower(right[index]) return false;
    return true;
}

generator_is_assembly_source :: (path: string) -> bool {
    extension := generator_path_extension(path);
    return generator_string_equals_ascii_case_insensitive(extension, ".s") ||
           generator_string_equals_ascii_case_insensitive(extension, ".sx") ||
           generator_string_equals_ascii_case_insensitive(extension, ".asm");
}

generator_is_c_source :: (path: string) -> bool {
    extension := generator_path_extension(path);
    return generator_string_equals_ascii_case_insensitive(extension, ".c") ||
           generator_string_equals_ascii_case_insensitive(extension, ".cc") ||
           generator_string_equals_ascii_case_insensitive(extension, ".cpp") ||
           generator_string_equals_ascii_case_insensitive(extension, ".cxx") ||
           generator_is_assembly_source(path);
}

generator_make_variable_name :: (value: string) -> string {
    separator := compat_string_find(value, "=");
    if separator <= 0 return "";
    name := compat_string_slice(value, 0, separator);
    for byte, index: name {
        valid := (byte >= #char "A" && byte <= #char "Z") ||
                 (byte >= #char "a" && byte <= #char "z") || byte == #char "_" ||
                 (index > 0 && byte >= #char "0" && byte <= #char "9");
        if !valid return "";
    }
    return name;
}

generator_make_environment :: (variables: [] string) -> [..] Translator_Process_Environment_Override {
    result: [..] Translator_Process_Environment_Override;
    for variable: variables {
        name := generator_make_variable_name(variable);
        if !name.count generator_error(tprint("Make variable must use KEY=VALUE: %", variable));
        separator := compat_string_find(variable, "=");
        array_add(*result, .{
            name = name,
            value = compat_string_slice(variable, separator + 1, variable.count),
        });
    }
    return result;
}

generator_prepare_make_native :: (
    directory: string,
    configure_script: string,
    configure_arguments: [] string,
    variables: [] string,
    generated_targets: [] string,
) {
    assert(File.make_directory_if_it_does_not_exist(directory, recursive = true));
    if !compat_path_exists(configure_script)
        generator_error(tprint("pinned Make configure script does not exist: %", configure_script));
    overrides := generator_make_environment(variables);
    defer array_free(overrides);
    configure: [..] string;
    defer array_free(configure);
    array_add(*configure, configure_script);
    array_add(*configure, ..configure_arguments);
    generator_run_checked(configure, directory, "configure pinned Make source", overrides);

    if generated_targets.count {
        arguments: [..] string;
        defer array_free(arguments);
        array_add(*arguments, "make", "-j1");
        array_add(*arguments, ..variables);
        array_add(*arguments, ..generated_targets);
        generator_run_checked(arguments, directory, "generate Make headers");
    }
}

generator_write_make_compile_database_native :: (
    path: string,
    directory: string,
    variables: [] string,
    targets: [] string,
) {
    arguments: [..] string;
    defer array_free(arguments);
    array_add(*arguments, "make", "-n");
    array_add(*arguments, ..variables);
    array_add(*arguments, ..targets);
    result := translator_process_run_output(arguments, directory);
    defer translator_process_output_result_deinit(*result);
    log: String_Builder;
    append(*log, result.output);
    append(*log, result.error);
    log_text := builder_to_string(*log);
    defer port_owned_string_drop(*log_text);
    log_path := tprint("%/generator-dry-run.log", directory);
    assert(File.write_entire_file(log_path, log_text));
    if !generator_process_succeeded(*result)
        generator_error(tprint("Make source query failed; see %", log_path));

    builder: String_Builder;
    append(*builder, "[\n");
    seen: [..] string;
    defer array_free(seen);
    lines := compat_string_lines(result.output);
    defer array_free(lines);
    unit_count := 0;
    for line: lines {
        words := generator_shell_words(line);
        defer deinit(*words);
        if !words.valid || words.values.count == 0 continue;
        compiler := generator_path_file_name(words.values[0]);
        if compiler == "nasm" || compiler == "yasm" || compiler == "as" || compiler == "llvm-mc"
            generator_error(tprint("configured source graph contains untranslated assembly: %", line));
        if !(compiler == "cc" || compiler == "c++" || compiler == "gcc" || compiler == "g++" ||
             compiler == "clang" || compiler == "clang++") continue;
        if !generator_string_array_contains(words.values, "-c") continue;

        source_argument := "";
        source_count := 0;
        for word: words.values if generator_is_c_source(word) {
            source_argument = word;
            source_count += 1;
        }
        if source_count != 1
            generator_error(tprint("cannot identify exactly one source in compiler recipe: %", line));
        source_candidate := ifx compat_path_is_absolute(source_argument)
            then source_argument else tprint("%/%", directory, source_argument);
        source, source_ok := File.get_absolute_path(source_candidate);
        if !source_ok generator_error(tprint("could not resolve Make source: %", source_candidate));
        if generator_is_assembly_source(source)
            generator_error(tprint("configured source graph contains untranslated assembly: %", source));
        if generator_string_array_contains(seen, source)
            generator_error(tprint("duplicate source recipe requires explicit variant identity: %", source));
        array_add(*seen, copy_string(source));

        if unit_count append(*builder, ",\n");
        append(*builder, "  {\n    \"directory\": ");
        generator_json_append_string(*builder, directory);
        append(*builder, ",\n    \"file\": ");
        generator_json_append_string(*builder, source);
        append(*builder, ",\n    \"arguments\": ");
        generator_json_append_array(*builder, words.values, "      ");
        append(*builder, "\n  }");
        unit_count += 1;
    }
    for *value: seen port_owned_string_drop(value);
    if unit_count == 0 generator_error("Make query returned no C/C++ compilation commands");
    append(*builder, "\n]\n");
    output_parent := compat_path_parent(path);
    if output_parent.has_value assert(File.make_directory_if_it_does_not_exist(output_parent.value, recursive = true));
    output := builder_to_string(*builder);
    defer port_owned_string_drop(*output);
    assert(File.write_entire_file(path, output));
    print("Selected % configured Make source units.\n", unit_count);
}

generator_cmake_target_is_valid :: (target: string) -> bool {
    if !target.count return false;
    for byte: target {
        valid := (byte >= #char "A" && byte <= #char "Z") ||
                 (byte >= #char "a" && byte <= #char "z") ||
                 (byte >= #char "0" && byte <= #char "9") ||
                 byte == #char "_" || byte == #char "." || byte == #char "+" ||
                 byte == #char ":" || byte == #char "-";
        if !valid return false;
    }
    return true;
}

generator_prepare_cmake_system_links :: (directory: string, targets: [] string) {
    query_directory := tprint("%/.cmake/api/v1/query", directory);
    assert(File.make_directory_if_it_does_not_exist(query_directory, recursive = true));
    assert(File.write_entire_file(tprint("%/codemodel-v2", query_directory), ""));
    source := tprint("%/generator_link_probe.c", directory);
    assert(File.write_entire_file(source, "int main(void) { return 0; }\n"));

    cmake: String_Builder;
    append(*cmake, "include_guard(GLOBAL)\nfunction(generator_record_system_links)\n");
    for target, index: targets {
        if !generator_cmake_target_is_valid(target)
            generator_error(tprint("invalid CMake target: %", target));
        append(*cmake, tprint("  add_executable(generator_system_link_probe_% EXCLUDE_FROM_ALL [[%]])\n", index, source));
        append(*cmake, tprint("  target_link_libraries(generator_system_link_probe_% PRIVATE [[%]])\n", index, target));
    }
    append(*cmake, "endfunction()\ncmake_language(DEFER DIRECTORY \"${CMAKE_SOURCE_DIR}\" CALL generator_record_system_links)\n");
    cmake_text := builder_to_string(*cmake);
    defer port_owned_string_drop(*cmake_text);
    assert(File.write_entire_file(tprint("%/generator_system_links.cmake", directory), cmake_text));

    target_document: String_Builder;
    generator_json_append_array(*target_document, targets, "  ");
    append(*target_document, #char "\n");
    target_text := builder_to_string(*target_document);
    defer port_owned_string_drop(*target_text);
    assert(File.write_entire_file(tprint("%/generator_system_targets.json", directory), target_text));
}

generator_json_string_array :: (value: *Json_Value, label: string) -> [..] string {
    result: [..] string;
    if value == null || value.type != .ARRAY generator_error(tprint("% must be a JSON array", label));
    for item: value.array {
        if item.type != .STRING generator_error(tprint("% must contain only strings", label));
        array_add(*result, item.str);
    }
    return result;
}

generator_compile_command_arguments :: (record: *Json_Value) -> Generator_Shell_Words {
    result: Generator_Shell_Words;
    arguments := json_get_array(record, "arguments");
    if arguments {
        result.valid = true;
        for argument: arguments.array {
            if argument.type != .STRING { result.valid = false; return result; }
            array_add(*result.values, copy_string(argument.str));
        }
        return result;
    }
    command := json_get_string(record, "command");
    if !command.count return result;
    return generator_shell_words(command);
}

generator_cmake_output_target :: (output: string) -> string {
    marker := "CMakeFiles/";
    begin := compat_string_find(output, marker);
    if begin < 0 return "";
    begin += marker.count;
    ending := compat_string_find_from(output, ".dir/", begin);
    if ending < 0 return "";
    return compat_string_slice(output, begin, ending);
}

generator_compile_command_is_assembly :: (file: string, arguments: [] string) -> bool {
    if generator_is_assembly_source(file) return true;
    if arguments.count {
        compiler := generator_path_file_name(arguments[0]);
        if compiler == "nasm" || compiler == "yasm" || compiler == "as" || compiler == "llvm-mc" return true;
    }
    for argument, index: arguments if argument == "-x" && index + 1 < arguments.count {
        language := arguments[index + 1];
        if language == "assembler" || language == "assembler-with-cpp" return true;
    }
    return false;
}

generator_compile_command_identity :: (directory: string, arguments: [] string) -> string {
    builder: String_Builder;
    generator_json_append_string(*builder, directory);
    append(*builder, #char "\n");
    cursor := 0;
    while cursor < arguments.count {
        if arguments[cursor] == "-o" {
            if cursor + 1 >= arguments.count generator_error("compile command has a missing -o argument");
            cursor += 2;
            continue;
        }
        generator_json_append_string(*builder, arguments[cursor]);
        append(*builder, #char "\n");
        cursor += 1;
    }
    return builder_to_string(*builder);
}

generator_write_cmake_compile_database_native :: (
    path: string,
    database_path: string,
    targets: [] string,
) {
    contents, ok := File.read_entire_file(database_path);
    if !ok generator_error(tprint("could not read CMake compilation database: %", database_path));
    defer free(contents.data);
    parsed := json_parse_with_result(contents);
    if !parsed.success generator_error(tprint("invalid CMake compilation database at %:%: %", parsed.error.line, parsed.error.column, parsed.error.message));
    defer json_free(parsed.value);
    if parsed.value.type != .ARRAY generator_error("CMake compilation database must be a JSON array");

    selected: Json_Value;
    selected.type = .ARRAY;
    defer array_free(selected.array);
    found: [..] string;
    defer array_free(found);
    files: [..] string;
    identities: [..] string;
    defer {
        for *value: files port_owned_string_drop(value);
        for *value: identities port_owned_string_drop(value);
        array_free(files);
        array_free(identities);
    }
    for record: parsed.value.array {
        if record.type != .OBJECT continue;
        target := generator_cmake_output_target(json_get_string(record, "output"));
        if !generator_string_array_contains(targets, target) continue;
        if !generator_string_array_contains(found, target) array_add(*found, target);
        file := json_get_string(record, "file");
        directory := json_get_string(record, "directory");
        if !file.count || !directory.count generator_error("CMake source command lacks file or directory");
        words := generator_compile_command_arguments(record);
        defer deinit(*words);
        if !words.valid || words.values.count == 0 generator_error(tprint("cannot parse CMake compiler command for %", file));
        if generator_compile_command_is_assembly(file, words.values)
            generator_error(tprint("configured CMake source graph contains untranslated assembly: %", file));
        identity := generator_compile_command_identity(directory, words.values);
        existing_index := -1;
        for existing, index: files if existing == file { existing_index = index; break; }
        if existing_index >= 0 {
            if identities[existing_index] != identity
                generator_error(tprint("CMake source % appears in multiple selected variants; give each variant a distinct source wrapper", file));
            port_owned_string_drop(*identity);
            continue;
        }
        array_add(*files, copy_string(file));
        array_add(*identities, identity);
        array_add(*selected.array, record);
    }
    for target: targets if !generator_string_array_contains(found, target)
        generator_error(tprint("CMake target has no compiler commands: %", target));
    output := json_serialize(*selected, .{pretty = true});
    defer free(output.data);
    assert(File.write_entire_file(path, tprint("%\n", output)));
}

Generator_CMake_Link_Info :: struct {
    arguments: [..] string;
    configuration: string;
}

deinit :: (info: *Generator_CMake_Link_Info) {
    if info == null return;
    for *value: info.arguments port_owned_string_drop(value);
    array_free(info.arguments);
    port_owned_string_drop(*info.configuration);
    info.* = .{};
}

Generator_Latest_CMake_Index :: struct {
    path: string;
    name: string;
}

generator_string_less :: (left: string, right: string) -> bool {
    common := ifx left.count < right.count then left.count else right.count;
    for index: 0..common-1 {
        if left[index] < right[index] return true;
        if left[index] > right[index] return false;
    }
    return left.count < right.count;
}

generator_find_latest_cmake_index :: (reply_directory: string) -> string {
    state: Generator_Latest_CMake_Index;
    visitor :: (info: *File_Utilities.File_Visit_Info, state: *Generator_Latest_CMake_Index) {
        if info.is_directory || !generator_string_starts_with(info.short_name, "index-") ||
           !generator_string_ends_with(info.short_name, ".json") return;
        if state.name.count && !generator_string_less(state.name, info.short_name) return;
        port_owned_string_drop(*state.name);
        port_owned_string_drop(*state.path);
        state.name = copy_string(info.short_name);
        state.path = copy_string(info.full_name);
    }
    if !File_Utilities.visit_files(
        reply_directory, false, *state, visitor,
        visit_files = true, visit_directories = false,
    ) generator_error(tprint("could not enumerate CMake file-api reply: %", reply_directory));
    port_owned_string_drop(*state.name);
    if !state.path.count generator_error("CMake file API produced no codemodel index");
    return state.path;
}

generator_parse_json_file :: (path: string) -> *Json_Value {
    contents, ok := File.read_entire_file(path);
    if !ok generator_error(tprint("could not read JSON file: %", path));
    parsed := json_parse_with_result(contents);
    free(contents.data);
    if !parsed.success generator_error(tprint(
        "invalid JSON in % at %:%: %", path,
        parsed.error.line, parsed.error.column, parsed.error.message,
    ));
    return parsed.value;
}

generator_cmake_link_arguments :: (directory: string, selected: [] string) -> Generator_CMake_Link_Info {
    reply_directory := tprint("%/.cmake/api/v1/reply", directory);
    index_path := generator_find_latest_cmake_index(reply_directory);
    defer port_owned_string_drop(*index_path);
    index_document := generator_parse_json_file(index_path);
    defer json_free(index_document);
    reply := json_get_object(index_document, "reply");
    codemodel_reference := json_get_object(reply, "codemodel-v2");
    codemodel_name := json_get_string(codemodel_reference, "jsonFile");
    if !codemodel_name.count generator_error("CMake file API index lacks codemodel-v2");
    model_document := generator_parse_json_file(tprint("%/%", reply_directory, codemodel_name));
    defer json_free(model_document);

    configured_targets_document := generator_parse_json_file(tprint("%/generator_system_targets.json", directory));
    defer json_free(configured_targets_document);
    configured_targets := generator_json_string_array(configured_targets_document, "CMake system target list");
    defer array_free(configured_targets);
    probe_names: [..] string;
    defer {
        for *name: probe_names port_owned_string_drop(name);
        array_free(probe_names);
    }
    for target: selected {
        target_index := -1;
        for configured, index: configured_targets if configured == target { target_index = index; break; }
        if target_index < 0 generator_error(tprint("CMake link target was not prepared: %", target));
        array_add(*probe_names, copy_string(tprint("generator_system_link_probe_%", target_index)));
    }

    configurations := json_get_array(model_document, "configurations");
    if configurations == null || configurations.array.count != 1
        generator_error("system-library resolution requires one configured CMake build profile");
    configuration := configurations.array[0];
    descriptors := json_get_array(configuration, "targets");
    if descriptors == null generator_error("CMake codemodel configuration lacks targets");
    result: Generator_CMake_Link_Info;
    result.configuration = copy_string(json_get_string(configuration, "name"));
    found: [..] string;
    defer array_free(found);

    for descriptor: descriptors.array {
        name := json_get_string(descriptor, "name");
        is_probe := generator_string_array_contains(probe_names, name);
        if !is_probe && !generator_string_array_contains(selected, name) continue;
        if is_probe && !generator_string_array_contains(found, name) array_add(*found, name);
        json_file := json_get_string(descriptor, "jsonFile");
        if !json_file.count generator_error(tprint("CMake codemodel target % lacks jsonFile", name));
        target_document := generator_parse_json_file(tprint("%/%", reply_directory, json_file));
        link := json_get_object(target_document, "link");
        fragments := json_get_array(link, "commandFragments");
        if fragments for fragment: fragments.array {
            role := json_get_string(fragment, "role");
            if role != "libraries" && role != "libraryPath" continue;
            words := generator_shell_words(json_get_string(fragment, "fragment"));
            if !words.valid {
                deinit(*words);
                json_free(target_document);
                generator_error(tprint("could not parse CMake link fragment for target %", name));
            }
            for word: words.values array_add(*result.arguments, copy_string(word));
            deinit(*words);
        }
        json_free(target_document);
    }
    for probe: probe_names if !generator_string_array_contains(found, probe)
        generator_error(tprint("CMake omitted requested link probe: %", probe));
    return result;
}

generator_path_is_within :: (path: string, directory: string) -> bool {
    if path.count < directory.count return false;
    for byte, index: directory if path[index] != byte return false;
    return path.count == directory.count || path[directory.count] == #char "/";
}

Generator_System_Library :: struct {
    path: string;
    soname: string;
    sha256: string;
    symbols: [..] string;
}

deinit :: (library: *Generator_System_Library) {
    if library == null return;
    port_owned_string_drop(*library.path);
    port_owned_string_drop(*library.soname);
    port_owned_string_drop(*library.sha256);
    for *symbol: library.symbols port_owned_string_drop(symbol);
    array_free(library.symbols);
    library.* = .{};
}

generator_sha256 :: (path: string) -> string {
    output := generator_run_capture(string.["sha256sum", "--", path], "", tprint("hash %", path));
    defer port_owned_string_drop(*output);
    trimmed := generator_trim_line_endings(output);
    separator := compat_string_find(trimmed, " ");
    if separator != 64 generator_error(tprint("sha256sum returned malformed output for %", path));
    return copy_string(compat_string_slice(trimmed, 0, separator));
}

generator_string_insert_sorted_unique :: (values: *[..] string, value: string) {
    insertion := 0;
    while insertion < values.count && generator_string_less(values.*[insertion], value) insertion += 1;
    if insertion < values.count && values.*[insertion] == value return;
    array_add(values, copy_string(""));
    cursor := values.count - 1;
    while cursor > insertion {
        values.*[cursor] = values.*[cursor - 1];
        cursor -= 1;
    }
    values.*[insertion] = copy_string(value);
}

generator_system_library_symbols :: (path: string, shared: bool) -> [..] string {
    arguments: [..] string;
    defer array_free(arguments);
    array_add(*arguments, "nm");
    if shared array_add(*arguments, "-D");
    array_add(*arguments, "-g", "--defined-only", "--format=posix", path);
    output := generator_run_capture(arguments, "", tprint("inspect exports from %", path));
    defer port_owned_string_drop(*output);
    lines := compat_string_lines(output);
    defer array_free(lines);
    result: [..] string;
    for line: lines {
        words := generator_shell_words(line);
        defer deinit(*words);
        if !words.valid || words.values.count < 2 || words.values[1].count != 1 continue;
        symbol := words.values[0];
        version := compat_string_find(symbol, "@");
        if version >= 0 {
            if version + 1 >= symbol.count || symbol[version + 1] != #char "@" continue;
            symbol = compat_string_slice(symbol, 0, version);
        }
        generator_string_insert_sorted_unique(*result, symbol);
    }
    return result;
}

generator_system_library_soname :: (path: string, shared: bool) -> string {
    if shared {
        output := generator_run_capture(string.["readelf", "-d", path], "", tprint("inspect SONAME for %", path));
        defer port_owned_string_drop(*output);
        marker := compat_string_find(output, "(SONAME)");
        if marker >= 0 {
            begin := compat_string_find_from(output, "[", marker);
            ending := ifx begin >= 0 then compat_string_find_from(output, "]", begin + 1) else -1;
            if begin >= 0 && ending > begin return copy_string(compat_string_slice(output, begin + 1, ending));
        }
    }
    return copy_string(generator_path_file_name(path));
}

generator_remove_c_comments :: (text: string) -> string {
    builder: String_Builder;
    cursor := 0;
    while cursor < text.count {
        if cursor + 1 < text.count && text[cursor] == #char "/" && text[cursor + 1] == #char "*" {
            ending := compat_string_find_from(text, "*/", cursor + 2);
            if ending < 0 break;
            cursor = ending + 2;
            continue;
        }
        append(*builder, text[cursor]);
        cursor += 1;
    }
    return builder_to_string(*builder);
}

generator_linker_script_words :: (text: string) -> Generator_Shell_Words {
    clean := generator_remove_c_comments(text);
    defer port_owned_string_drop(*clean);
    group := compat_string_find(clean, "GROUP");
    input := compat_string_find(clean, "INPUT");
    marker := ifx group < 0 then input else ifx input < 0 || group < input then group else input;
    if marker < 0 return .{};
    begin := compat_string_find_from(clean, "(", marker);
    if begin < 0 return .{};
    depth := 1;
    ending := begin + 1;
    while ending < clean.count && depth > 0 {
        if clean[ending] == #char "(" depth += 1;
        else if clean[ending] == #char ")" depth -= 1;
        ending += 1;
    }
    if depth != 0 return .{};
    flattened: String_Builder;
    for cursor: begin + 1..ending - 2 {
        byte := clean[cursor];
        append(*flattened, ifx byte == #char "(" || byte == #char ")" then #char " " else byte);
    }
    flattened_text := builder_to_string(*flattened);
    defer port_owned_string_drop(*flattened_text);
    return generator_shell_words(flattened_text);
}

generator_resolve_library_candidate :: (
    request: string, search_paths: [] string,
) -> string {
    names: [..] string;
    defer array_free(names);
    if generator_string_starts_with(request, "-l:") array_add(*names, compat_string_slice(request, 3, request.count));
    else if generator_string_starts_with(request, "-l") {
        base := compat_string_slice(request, 2, request.count);
        array_add(*names, tprint("lib%.so", base), tprint("lib%.a", base));
    } else array_add(*names, request);

    for directory: search_paths for name: names {
        candidate := tprint("%/%", directory, name);
        if compat_path_exists(candidate) {
            absolute, ok := File.get_absolute_path(candidate);
            if ok return copy_string(absolute);
        }
    }
    for name: names {
        if compat_path_is_absolute(name) && compat_path_exists(name) {
            absolute, ok := File.get_absolute_path(name);
            if ok return copy_string(absolute);
        }
        output := generator_run_capture(
            string.["clang", tprint("-print-file-name=%", name)], "",
            tprint("resolve system library %", request),
        );
        defer port_owned_string_drop(*output);
        candidate := generator_trim_line_endings(output);
        if compat_path_is_absolute(candidate) && compat_path_exists(candidate) {
            absolute, ok := File.get_absolute_path(candidate);
            if ok return copy_string(absolute);
        }
    }
    generator_error(tprint("cannot resolve explicitly linked system library %", request));
    return "";
}

generator_resolve_system_libraries_native :: (
    output_path: string,
    explicit_libraries: [] string,
    cmake_directory: string = "",
    targets: [] string = .[],
) {
    link_info: Generator_CMake_Link_Info;
    if cmake_directory.count link_info = generator_cmake_link_arguments(cmake_directory, targets);
    defer deinit(*link_info);
    requests: [..] string;
    search_paths: [..] string;
    ignored: [..] string;
    defer {
        for *value: requests port_owned_string_drop(value);
        for *value: search_paths port_owned_string_drop(value);
        for *value: ignored port_owned_string_drop(value);
        array_free(requests); array_free(search_paths); array_free(ignored);
    }

    cursor := 0;
    while cursor < link_info.arguments.count {
        argument := link_info.arguments[cursor];
        if argument == "-L" && cursor + 1 < link_info.arguments.count {
            cursor += 1;
            array_add(*search_paths, copy_string(link_info.arguments[cursor]));
        } else if generator_string_starts_with(argument, "-L") {
            array_add(*search_paths, copy_string(compat_string_slice(argument, 2, argument.count)));
        } else if generator_string_starts_with(argument, "-l") {
            array_add(*requests, copy_string(argument));
        } else if !generator_string_starts_with(argument, "-") {
            candidate := ifx compat_path_is_absolute(argument)
                then argument else tprint("%/%", cmake_directory, argument);
            if generator_path_is_within(candidate, cmake_directory)
                array_add(*ignored, copy_string(candidate));
            else array_add(*requests, copy_string(candidate));
        }
        cursor += 1;
    }
    for library: explicit_libraries array_add(*requests, copy_string(library));
    array_add(*requests, copy_string("libc.so.6"), copy_string("libm.so.6"), copy_string("libstdc++.so.6"));

    libraries: [..] Generator_System_Library;
    paths: [..] string;
    loader_names: [..] string;
    defer {
        for *library: libraries deinit(library);
        for *value: paths port_owned_string_drop(value);
        for *value: loader_names port_owned_string_drop(value);
        array_free(libraries); array_free(paths); array_free(loader_names);
    }

    request_index := 0;
    while request_index < requests.count {
        request := requests[request_index];
        request_index += 1;
        path := generator_resolve_library_candidate(request, search_paths);
        if generator_string_array_contains(paths, path) { port_owned_string_drop(*path); continue; }
        array_add(*paths, copy_string(path));
        loader_name := generator_path_file_name(path);
        for existing, index: loader_names if existing == loader_name && paths[index] != path
            generator_error(tprint("distinct configured libraries share loader filename %", loader_name));
        array_add(*loader_names, copy_string(loader_name));

        contents, ok := File.read_entire_file(path);
        if !ok generator_error(tprint("could not read system library: %", path));
        shared := contents.count >= 4 && contents[0] == 0x7f && contents[1] == #char "E" &&
                  contents[2] == #char "L" && contents[3] == #char "F";
        archive := generator_string_starts_with(contents, "!<arch>\n");
        if !shared && !archive {
            words := generator_linker_script_words(contents);
            free(contents.data);
            defer deinit(*words);
            if !words.valid
                generator_error(tprint("unsupported system-library linker script: %", path));
            for word: words.values {
                if word == "AS_NEEDED" continue;
                if generator_string_starts_with(word, "-l") array_add(*requests, copy_string(word));
                else {
                    parent := compat_path_parent(path);
                    entry := ifx compat_path_is_absolute(word) then word else tprint("%/%", parent.value, word);
                    array_add(*requests, copy_string(entry));
                }
            }
            port_owned_string_drop(*path);
            continue;
        }
        free(contents.data);

        library: Generator_System_Library;
        library.path = path;
        library.soname = generator_system_library_soname(path, shared);
        library.sha256 = generator_sha256(path);
        library.symbols = generator_system_library_symbols(path, shared);
        array_add(*libraries, library);
    }

    builder: String_Builder;
    append(*builder, "{\n  \"schema\": 1,\n  \"profile\": {");
    if cmake_directory.count {
        append(*builder, "\n    \"build_directory\": ");
        generator_json_append_string(*builder, cmake_directory);
        append(*builder, ",\n    \"configuration\": ");
        generator_json_append_string(*builder, link_info.configuration);
        append(*builder, ",\n    \"targets\": ");
        generator_json_append_array(*builder, targets, "      ");
        append(*builder, ",\n    \"link_arguments\": ");
        generator_json_append_array(*builder, link_info.arguments, "      ");
        append(*builder, "\n  ");
    }
    append(*builder, "},\n  \"ignored_source_libraries\": ");
    generator_json_append_array(*builder, ignored, "    ");
    append(*builder, ",\n  \"libraries\": [\n");
    for library, index: libraries {
        append(*builder, "    {\n      \"path\": ");
        generator_json_append_string(*builder, library.path);
        append(*builder, ",\n      \"soname\": ");
        generator_json_append_string(*builder, library.soname);
        append(*builder, ",\n      \"sha256\": ");
        generator_json_append_string(*builder, library.sha256);
        append(*builder, ",\n      \"symbols\": ");
        generator_json_append_array(*builder, library.symbols, "        ");
        append(*builder, "\n    }");
        if index + 1 < libraries.count append(*builder, #char ",");
        append(*builder, #char "\n");
    }
    append(*builder, "  ]\n}\n");
    output := builder_to_string(*builder);
    defer port_owned_string_drop(*output);
    assert(File.write_entire_file(output_path, output));
}

generator_test_environment :: (manifest_path: string) -> [..] Translator_Process_Environment_Override {
    document := generator_parse_json_file(manifest_path);
    defer json_free(document);
    libraries := json_get_array(document, "libraries");
    if libraries == null || json_get_int(document, "schema") != 1
        generator_error(tprint("invalid configured system library manifest: %", manifest_path));
    directories: [..] string;
    defer {
        for *directory: directories port_owned_string_drop(directory);
        array_free(directories);
    }
    for library: libraries.array {
        path := json_get_string(library, "path");
        expected := json_get_string(library, "sha256");
        if !path.count || !expected.count generator_error("system library entry lacks path or sha256");
        actual := generator_sha256(path);
        if actual != expected generator_error(tprint("configured system library changed after resolution: %", path));
        port_owned_string_drop(*actual);
        parent := compat_path_parent(path);
        if parent.has_value && !generator_string_array_contains(directories, parent.value)
            array_add(*directories, copy_string(parent.value));
    }
    existing_pointer := POSIX.getenv("LD_LIBRARY_PATH");
    existing := ifx existing_pointer then to_string(existing_pointer) else "";
    builder: String_Builder;
    for directory, index: directories {
        if index append(*builder, #char ":");
        append(*builder, directory);
    }
    if existing.count {
        if directories.count append(*builder, #char ":");
        append(*builder, existing);
    }
    value := builder_to_string(*builder);
    result: [..] Translator_Process_Environment_Override;
    array_add(*result, .{name = copy_string("LD_LIBRARY_PATH"), value = value});
    return result;
}

generator_test_environment_deinit :: (environment: *[..] Translator_Process_Environment_Override) {
    if environment == null return;
    for *entry: environment.* {
        port_owned_string_drop(*entry.name);
        port_owned_string_drop(*entry.value);
    }
    array_free(environment.*);
}

generator_internal_option_value :: (arguments: [] string, cursor: *int, option: string) -> string {
    if cursor.* + 1 >= arguments.count generator_error(tprint("% requires a value", option));
    cursor.* += 1;
    return arguments[cursor.*];
}

generator_internal_system_libraries :: (arguments: [] string) {
    if arguments.count < 3 generator_error("internal system-library tool requires a mode");
    mode := arguments[2];
    cmake_directory := "";
    output := "";
    database := "";
    manifest := "";
    targets: [..] string;
    libraries: [..] string;
    defer { array_free(targets); array_free(libraries); }
    cursor := 3;
    command_begin := arguments.count;
    while cursor < arguments.count {
        argument := arguments[cursor];
        if argument == "--cmake-build" cmake_directory = generator_internal_option_value(arguments, *cursor, argument);
        else if argument == "--output" output = generator_internal_option_value(arguments, *cursor, argument);
        else if argument == "--database" database = generator_internal_option_value(arguments, *cursor, argument);
        else if argument == "--manifest" manifest = generator_internal_option_value(arguments, *cursor, argument);
        else if argument == "--target" array_add(*targets, generator_internal_option_value(arguments, *cursor, argument));
        else if argument == "--library" array_add(*libraries, generator_internal_option_value(arguments, *cursor, argument));
        else if argument == "--command" { command_begin = cursor + 1; break; }
        else generator_error(tprint("unknown internal system-library option: %", argument));
        cursor += 1;
    }
    if mode == "prepare" {
        if !cmake_directory.count generator_error("system-library prepare requires --cmake-build");
        generator_prepare_cmake_system_links(cmake_directory, targets);
    } else if mode == "select" {
        if !database.count || !output.count generator_error("system-library select requires --database and --output");
        generator_write_cmake_compile_database_native(output, database, targets);
    } else if mode == "resolve" {
        if !output.count generator_error("system-library resolve requires --output");
        generator_resolve_system_libraries_native(output, libraries, cmake_directory, targets);
    } else if mode == "run" {
        if !manifest.count || command_begin >= arguments.count
            generator_error("system-library run requires --manifest and --command");
        environment := generator_test_environment(manifest);
        defer generator_test_environment_deinit(*environment);
        command: [] string;
        command.data = arguments.data + command_begin;
        command.count = arguments.count - command_begin;
        result := translator_process_run_output(command, "", environment);
        defer translator_process_output_result_deinit(*result);
        if result.output.count write_string(result.output);
        if result.error.count write_string(result.error, to_standard_error = true);
        if !generator_process_succeeded(*result) {
            if result.launch_error
                write_string(tprint("launch error: %\n", result.launch_error), to_standard_error = true);
            exit(ifx result.process.type == .EXITED then result.process.exit_code else 1);
        }
    } else generator_error(tprint("unknown internal system-library mode: %", mode));
}

generator_internal_make_sources :: (arguments: [] string) {
    if arguments.count < 3 generator_error("internal Make-source tool requires a mode");
    mode := arguments[2];
    directory := "";
    configure_script := "";
    output := "";
    configure_arguments: [..] string;
    variables: [..] string;
    targets: [..] string;
    defer { array_free(configure_arguments); array_free(variables); array_free(targets); }
    cursor := 3;
    while cursor < arguments.count {
        argument := arguments[cursor];
        if argument == "--directory" directory = generator_internal_option_value(arguments, *cursor, argument);
        else if argument == "--configure-script" configure_script = generator_internal_option_value(arguments, *cursor, argument);
        else if argument == "--output" output = generator_internal_option_value(arguments, *cursor, argument);
        else if argument == "--variable" array_add(*variables, generator_internal_option_value(arguments, *cursor, argument));
        else if argument == "--target" array_add(*targets, generator_internal_option_value(arguments, *cursor, argument));
        else if generator_string_starts_with(argument, "--variable=")
            array_add(*variables, compat_string_slice(argument, "--variable=".count, argument.count));
        else if generator_string_starts_with(argument, "--configure-argument=")
            array_add(*configure_arguments, compat_string_slice(argument, "--configure-argument=".count, argument.count));
        else generator_error(tprint("unknown internal Make-source option: %", argument));
        cursor += 1;
    }
    if !directory.count generator_error("internal Make-source tool requires --directory");
    if mode == "prepare" {
        if !configure_script.count generator_error("Make prepare requires --configure-script");
        generator_prepare_make_native(directory, configure_script, configure_arguments, variables, targets);
    } else if mode == "select" {
        if !output.count generator_error("Make select requires --output");
        generator_write_make_compile_database_native(output, directory, variables, targets);
    } else generator_error(tprint("unknown internal Make-source mode: %", mode));
}
