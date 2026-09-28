#import "Basic";
Lz4 :: #import "lz4";

main :: () {
    Lz4.initialize_program();
    digest := verify_compression();
    // Golden digest independently produced by the pinned upstream C oracle.
    assert(digest == 10233266375463304189);
    print("PARITY lz4 %\n", digest);
    if array_find(get_command_line_arguments(), "--benchmark") {
        started := seconds_since_init();
        checksum: u64;
        for iteration: 0..19 checksum += verify_compression(cast(u32) iteration);
        print("BENCH % %\n", seconds_since_init() - started, checksum);
    }
}
mix :: (digest: *u64, value: u64) { digest.* = (digest.* ^ value) * 1099511628211; }
verify_compression :: (salt: u32 = 0) -> u64 {
    digest: u64 = 14695981039346656037;
    lengths := s32.[0, 1, 7, 15, 31, 256, 1024, 4096, 16384];
    levels := s32.[0, 1, 9, 12];
    source: [16384] u8 = ---;
    compressed: [18000] u8 = ---;
    restored: [16384] u8 = ---;
    for pattern: 0..3 {
        random: u32 = 123456789 ^ salt;
        for *value, index: source {
            random = random ^ (random << 13); random = random ^ (random >> 17); random = random ^ (random << 5);
            if pattern == 0 value.* = cast,no_check(u8) (index * 73 + index / 7 + salt);
            if pattern == 1 value.* = cast,no_check(u8) salt;
            if pattern == 2 value.* = cast,no_check(u8) (index / 13 + salt);
            if pattern == 3 value.* = cast,no_check(u8) random;
        }
        for count: lengths {
            for level: levels {
                compressed_count: s32;
                if level == 0 compressed_count = Lz4.compress_default(cast(*s8) source.data, cast(*s8) compressed.data, count, 18000);
                else compressed_count = Lz4.compress_hc(cast(*s8) source.data, cast(*s8) compressed.data, count, 18000, level);
                assert(compressed_count > 0 && compressed_count <= Lz4.compress_bound(count));
                mix(*digest, cast(u64) compressed_count);
                for index: 0..cast(s64) compressed_count - 1 mix(*digest, compressed[index]);
                result := Lz4.decompress_safe(cast(*s8) compressed.data, cast(*s8) restored.data, compressed_count, 16384);
                assert(result == count);
                for index: 0..cast(s64) count - 1 assert(restored[index] == source[index]);
                result = Lz4.decompress_safe(cast(*s8) compressed.data, cast(*s8) restored.data, compressed_count / 2, 16384);
                // A raw block prefix may itself be a valid shorter block.
                mix(*digest, cast,no_check(u64) result);
                if count > 1 {
                    result = Lz4.decompress_safe(cast(*s8) compressed.data, cast(*s8) restored.data, compressed_count, 1);
                    assert(result < 0);
                    mix(*digest, cast,no_check(u64) result);
                }
            }
            size := Lz4.f_compress_frame(compressed.data, 18000, source.data, cast(u64) count, null);
            assert(Lz4.f_is_error(size) == 0);
            mix(*digest, size);
            for index: 0..cast(s64) size - 1 mix(*digest, compressed[index]);
            ctx: *Lz4.F_Dctx;
            assert(Lz4.f_create_decompression_context(*ctx, 100) == 0);
            output_count: u64 = 16384;
            consumed := size;
            result := Lz4.f_decompress(ctx, restored.data, *output_count, compressed.data, *consumed, null);
            assert(result == 0 && output_count == cast(u64) count && consumed == size);
            assert(Lz4.f_free_decompression_context(ctx) == 0);
            for index: 0..cast(s64) count - 1 assert(restored[index] == source[index]);
        }
    }
    verify_dictionary(*digest, salt);
    return digest;
}

verify_dictionary :: (digest: *u64, salt: u32) {
    dictionary_sizes := s32.[0, 1, 256, 65536];
    accelerations := s32.[1, 3, 9];
    dictionary: [65536] u8 = ---;
    source: [32768] u8 = ---;
    restored: [32768] u8 = ---;
    compressed: [18000] u8 = ---;
    for *byte, index: dictionary byte.* = cast,no_check(u8) (index * 19 + index / 7 + salt);
    for *byte, index: source byte.* = dictionary[(index + 32768) & 65535];
    for dictionary_size: dictionary_sizes for acceleration: accelerations {
        encoder := Lz4.create_stream(); assert(encoder != null);
        decoder := Lz4.create_stream_decode(); assert(decoder != null);
        loaded := Lz4.load_dict(encoder, cast(*s8) dictionary.data, dictionary_size);
        mix(digest, cast(u64) loaded);
        assert(Lz4.set_stream_decode(decoder, cast(*s8) dictionary.data, dictionary_size) == 1);
        for block: 0..1 {
            size := Lz4.compress_fast_continue(encoder, cast(*s8) (source.data + block * 16384), cast(*s8) compressed.data, 16384, 18000, acceleration);
            assert(size > 0); mix(digest, cast(u64) size);
            for index: 0..cast(s64) size - 1 mix(digest, compressed[index]);
            count := Lz4.decompress_safe_continue(decoder, cast(*s8) compressed.data, cast(*s8) (restored.data + block * 16384), size, 16384);
            assert(count == 16384);
            for index: 0..16383 assert(restored[block * 16384 + index] == source[block * 16384 + index]);
            mix(digest, cast(u64) count);
        }
        assert(Lz4.free_stream(encoder) == 0);
        assert(Lz4.free_stream_decode(decoder) == 0);
    }
}
