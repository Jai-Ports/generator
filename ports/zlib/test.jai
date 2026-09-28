#import "Basic";
Zlib :: #import "zlib";

main :: () {
    Zlib.initialize_program();
    digest := verify_compression();
    // Golden digest independently produced by the pinned upstream C oracle.
    assert(digest == 18321882723032685780);
    print("PARITY zlib %\n", digest);
    if array_find(get_command_line_arguments(), "--benchmark") {
        started := seconds_since_init();
        checksum: u64;
        for iteration: 0..9 checksum += verify_compression(cast(u32) iteration);
        print("BENCH % %\n", seconds_since_init() - started, checksum);
    }
}

mix :: (digest: *u64, value: u64) {
    digest.* = (digest.* ^ value) * 1099511628211;
}

verify_compression :: (salt: u32 = 0) -> u64 {
    digest: u64 = 14695981039346656037;
    lengths := s32.[0, 1, 7, 15, 31, 256, 1024, 4096, 16384];
    source: [16384] u8 = ---;
    compressed: [17000] u8 = ---;
    restored: [16384] u8 = ---;
    for pattern: 0..3 {
        random: u32 = 123456789 ^ salt;
        for *value, index: source {
            random = random ^ (random << 13);
            random = random ^ (random >> 17);
            random = random ^ (random << 5);
            if pattern == 0 value.* = cast,no_check(u8) (index * 73 + index / 7 + salt);
            if pattern == 1 value.* = cast,no_check(u8) salt;
            if pattern == 2 value.* = cast,no_check(u8) (index / 13 + salt);
            if pattern == 3 value.* = cast,no_check(u8) random;
        }
        for count: lengths {
            mix(*digest, Zlib.adler32(1, source.data, cast(u32) count));
            mix(*digest, Zlib.crc32(0, source.data, cast(u32) count));
            for level: 0..9 {
                compressed_count := cast(u64) compressed.count;
                result := Zlib.compress2(compressed.data, *compressed_count,
                    source.data, cast(u64) count, cast(s32) level);
                assert(result == 0 && compressed_count <= Zlib.compress_bound(cast(u64) count));
                mix(*digest, compressed_count);
                for index: 0..cast(s64) compressed_count - 1 mix(*digest, compressed[index]);
                restored_count := cast(u64) restored.count;
                consumed := compressed_count;
                result = Zlib.uncompress2(restored.data, *restored_count, compressed.data, *consumed);
                if result != 0 || restored_count != cast(u64) count || consumed != compressed_count
                    print("zlib roundtrip mismatch pattern=% count=% level=% result=% restored=% consumed=% compressed=%\n",
                        pattern, count, level, result, restored_count, consumed, compressed_count);
                assert(result == 0 && restored_count == cast(u64) count && consumed == compressed_count);
                for index: 0..cast(s64) count - 1 assert(restored[index] == source[index]);

                // Truncated stream and insufficient destination handling.
                restored_count = cast(u64) restored.count;
                consumed = compressed_count / 2;
                result = Zlib.uncompress2(restored.data, *restored_count, compressed.data, *consumed);
                assert(result != 0);
                mix(*digest, cast,no_check(u64) result);
                if count > 1 {
                    restored_count = 1;
                    consumed = compressed_count;
                    result = Zlib.uncompress2(restored.data, *restored_count, compressed.data, *consumed);
                    assert(result == -5);
                    mix(*digest, cast,no_check(u64) result);
                }
                compressed[compressed_count - 1] = compressed[compressed_count - 1] ^ 1;
                restored_count = cast(u64) restored.count;
                consumed = compressed_count;
                result = Zlib.uncompress2(restored.data, *restored_count, compressed.data, *consumed);
                assert(result == -3);
                mix(*digest, cast,no_check(u64) result);
            }
        }
    }
    return digest;
}
