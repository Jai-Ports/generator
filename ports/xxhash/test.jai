#import "Basic";
Hash :: #import "xxhash";
main :: () {
    Hash.initialize_program();
    digest := verify_hashes(0, array_find(get_command_line_arguments(), "--dump"));
    // Golden digest independently produced by the pinned upstream C oracle.
    assert(digest == 13678638327611468053);
    print("PARITY xxhash %\n", digest);
    if array_find(get_command_line_arguments(), "--benchmark") {
        started := seconds_since_init();
        checksum: u64;
        for salt: 0..29 checksum += verify_hashes(cast(u64) salt);
        print("BENCH % %\n", seconds_since_init() - started, checksum);
    }
}
mix :: (digest: *u64, value: u64) { digest.* = (digest.* ^ value) * 1099511628211; }
verify_hashes :: (salt: u64 = 0, dump: bool = false) -> u64 {
    bytes: [8196] u8;
    random: u32 = 123456789;
    for *value: bytes {
        random = random ^ (random << 13); random = random ^ (random >> 17); random = random ^ (random << 5);
        value.* = cast,no_check(u8) random;
    }
    long_lengths := u64.[511, 512, 513, 1023, 1024, 1025, 4095, 4096, 8192];
    seeds := u64.[0, 1, 0xffffffffffffffff, 11400714819323198485];
    digest: u64 = 14695981039346656037;
    state32 := Hash.xxh32_create_state();
    state64 := Hash.xxh64_create_state();
    assert(state32 != null && state64 != null);
    defer Hash.xxh32_free_state(state32);
    defer Hash.xxh64_free_state(state64);
    for alignment: 0..3 for n: 0..265 for initial_seed: seeds {
        length := ifx n < 257 then cast(u64) n else long_lengths[n - 257];
        data := cast(*void) (bytes.data + alignment);
        seed := initial_seed ^ salt;
        hash32 := Hash.xxh32(data, length, cast,no_check(u32) seed);
        hash64 := Hash.xxh64(data, length, seed);
        hash3 := Hash.xxh3_64bits_with_seed(data, length, seed);
        hash128 := Hash.xxh3_128bits_with_seed(data, length, seed);
        if dump print("CASE % % % % % % % %\n",alignment,length,seed,hash32,hash64,hash3,hash128.low64,hash128.high64);
        mix(*digest, hash32); mix(*digest, hash64); mix(*digest, hash3);
        mix(*digest, hash128.low64); mix(*digest, hash128.high64);
        assert(Hash.xxh32_reset(state32, cast,no_check(u32) seed) == 0 && Hash.xxh64_reset(state64, seed) == 0);
        split := length / 3;
        assert(Hash.xxh32_update(state32, data, split) == 0);
        assert(Hash.xxh32_update(state32, cast(*void) (bytes.data + alignment + split), length - split) == 0);
        assert(Hash.xxh64_update(state64, data, split) == 0);
        assert(Hash.xxh64_update(state64, cast(*void) (bytes.data + alignment + split), length - split) == 0);
        assert(Hash.xxh32_digest(state32) == hash32 && Hash.xxh64_digest(state64) == hash64);
    }
    return digest;
}
