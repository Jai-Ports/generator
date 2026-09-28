// Lexical source normalization used only for generated private identifiers.
generator_source_slice :: (value: string, begin: int, end: int) -> string {
    return .{data = value.data + begin, count = end - begin};
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
    // Virtual dispatchers use a stable semantic overload ordinal. That
    // trailing number is part of the program-wide symbol name, not a
    // per-AST implementation ID. Canonicalizing each generated file in
    // isolation would therefore give the definition and its call sites
    // different `_gN` names.
    if generator_string_starts_with(
        identifier, "cpp_transpiler_dispatch_",
    ) return false;
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
            free(name.original.data);
            free(name.canonical.data);
        }
        array_free(names);
    }

    output: String_Builder;
    cursor := 0;
    while cursor < source.count {
        // Private identifiers may also occur as observable string data or in
        // comments. Only rename tokens in code, never their textual spelling
        // inside these regions. Jai block comments can be nested.
        literal_end := cursor;
        if source[cursor] == #char "\"" {
            literal_end += 1;
            while literal_end < source.count {
                byte := source[literal_end];
                literal_end += 1;
                if byte == #char "\\" && literal_end < source.count literal_end += 1;
                else if byte == #char "\"" break;
            }
        } else if cursor + 1 < source.count && source[cursor] == #char "/" {
            if source[cursor + 1] == #char "/" {
                literal_end = cursor + 2;
                while literal_end < source.count && source[literal_end] != #char "\n"
                    literal_end += 1;
            } else if source[cursor + 1] == #char "*" {
                literal_end = cursor + 2;
                depth := 1;
                while literal_end < source.count && depth {
                    if literal_end + 1 < source.count && source[literal_end] == #char "/" &&
                       source[literal_end + 1] == #char "*" { depth += 1; literal_end += 2; }
                    else if literal_end + 1 < source.count && source[literal_end] == #char "*" &&
                            source[literal_end + 1] == #char "/" { depth -= 1; literal_end += 2; }
                    else literal_end += 1;
                }
            }
        } else if source[cursor] == #char "#" && generator_string_starts_with(
            generator_source_slice(source, cursor, source.count), "#string ",
        ) {
            delimiter_begin := cursor + 8;
            while delimiter_begin < source.count && source[delimiter_begin] == #char " "
                delimiter_begin += 1;
            delimiter_end := delimiter_begin;
            while delimiter_end < source.count && generator_identifier_continue(source[delimiter_end])
                delimiter_end += 1;
            delimiter := generator_source_slice(source, delimiter_begin, delimiter_end);
            if delimiter.count {
                literal_end = delimiter_end;
                while literal_end < source.count {
                    if (literal_end == 0 || source[literal_end - 1] == #char "\n") &&
                       generator_string_starts_with(
                           generator_source_slice(source, literal_end, source.count), delimiter,
                       ) {
                        after := literal_end + delimiter.count;
                        if after == source.count || !generator_identifier_continue(source[after]) {
                            literal_end = after;
                            break;
                        }
                    }
                    literal_end += 1;
                }
            }
        }
        if literal_end > cursor {
            append(*output, generator_source_slice(source, cursor, literal_end));
            cursor = literal_end;
            continue;
        }
        if !generator_identifier_start(source[cursor]) {
            append(*output, source[cursor]);
            cursor += 1;
            continue;
        }
        end := cursor + 1;
        while end < source.count && generator_identifier_continue(source[end]) end += 1;
        identifier := generator_source_slice(source, cursor, end);
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
            base := generator_source_slice(identifier, 0, separator + 1);
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
