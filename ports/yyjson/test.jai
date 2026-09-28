#import "Basic";
Json :: #import "yyjson";
main :: () {
    Json.initialize_program();
    digest := verify_documents();
    assert(digest == 9523322153142335184);
    print("PARITY yyjson %\n", digest);
    if array_find(get_command_line_arguments(), "--benchmark") {
        started := seconds_since_init();
        checksum: u64;
        for 0..999 checksum += verify_documents();
        print("BENCH % %\n", seconds_since_init() - started, checksum);
    }
}
mix :: (digest: *u64, value: u64) { digest.* = (digest.* ^ value) * 1099511628211; }
verify_documents :: () -> u64 {
    inputs := string.[
        "null",
        "true",
        "false",
        "0",
        "-9223372036854775808",
        "18446744073709551615",
        "1.7976931348623157e308",
        "5e-324",
        "-0.0",
        "{\"a\":[1,2,3],\"text\":\"hello \\u00e9 \\ud83d\\ude80\",\"nested\":{\"ok\":true}}",
        "[1,2,]",
        "{/* comment */\"x\":2}",
        "{bare: 'value', hex: 0xFF}",
        "[1,",
        "{\"x\":01}",
        "\"\\ud800\"",
        "NaN",
        "",
    ];
    flags := u32.[0, Json.READ_ALLOW_TRAILING_COMMAS | Json.READ_ALLOW_COMMENTS, Json.READ_JSON5];
    write_flags := u32.[0, Json.WRITE_PRETTY, Json.WRITE_ESCAPE_UNICODE];
    digest: u64 = 14695981039346656037;
    for input: inputs for flag: flags {
        error: Json.Read_Err;
        doc := Json.read_opts(cast(*s8) input.data, cast(u64) input.count, flag, null, *error);
        mix(*digest, error.code);
        mix(*digest, error.pos);
        if doc == null continue;
        defer Json.doc_free(doc);
        mix(*digest, Json.doc_get_read_size(doc));
        mix(*digest, Json.doc_get_val_count(doc));
        for write_flag: write_flags {
            size: u64;
            write_error: Json.Write_Err;
            output := Json.write_opts(doc, write_flag, *doc.alc, *size, *write_error);
            mix(*digest, write_error.code);
            mix(*digest, size);
            if output != null {
                for index: 0..cast(s64) size - 1 mix(*digest, cast,no_check(u8) output[index]);
                doc.alc.free_(doc.alc.ctx, output);
            }
        }
    }
    return digest;
}
