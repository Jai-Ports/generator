#import "Basic";
Noise :: #import "fastnoise";

// Mirrors compact_fastnoise_reference.c. The differential runner compares all
// float bit patterns through this digest; this is finite input coverage.
main :: () {
    Noise.initialize_program();
    digest := verify_noise();
    assert(digest == 12140208305611705639);
    print("PARITY fastnoise %\n", digest);
    if array_find(get_command_line_arguments(), "--benchmark") {
        started := seconds_since_init();
        checksum: u64;
        for iteration: 0..39 checksum += verify_noise(cast(s32) iteration);
        print("BENCH % %\n", seconds_since_init() - started, checksum);
    }
}

add_sample :: (digest: *u64, sample: float32) {
    bits := (cast(*u32) *sample).*;
    digest.* = (digest.* ^ cast(u64) bits) * 1099511628211;
}

verify_noise :: (seed_offset: s32 = 0) -> u64 {
    digest: u64 = 14695981039346656037;
    seeds := s32.[-2147483648, -1, 0, 1, 1337, 2147483647];
    state: Noise.State;
    Noise.create_state(*state);
    assert(state.seed == 1337 && state.frequency == 0.01);
    for noise: 0..5 for fractal: 0..3 for rotation: 0..2
    for distance: 0..3 for return_type: 0..6 for point: 0..8 {
        state.noise_type = cast(u32) noise;
        state.fractal_type = cast(u32) fractal;
        state.rotation_type_3d = cast(u32) rotation;
        state.cellular_distance_func = cast(u32) distance;
        state.cellular_return_type = cast(u32) return_type;
        state.seed = seeds[point % seeds.count] ^ seed_offset;
        state.frequency = 0.03125;
        state.weighted_strength = 0.375;
        state.octaves = 4;
        x := cast(float32) (point - 4) * 11.125;
        y := cast(float32) (point * point - 17) * 0.875;
        z := cast(float32) (point * 3 - 11) * 7.25;
        add_sample(*digest, Noise.get_noise2_d(*state, x, y));
        add_sample(*digest, Noise.get_noise3_d(*state, x, y, z));
    }
    for warp: 0..2 for fractal: 0..2 for rotation: 0..2 for point: 0..8 {
        state.domain_warp_type = cast(u32) warp;
        state.fractal_type = ifx fractal == 0 then 0 else cast(u32) (fractal + 3);
        state.rotation_type_3d = cast(u32) rotation;
        state.seed = seeds[point % seeds.count] ^ seed_offset;
        x := cast(float32) (point - 4) * 11.125;
        y := cast(float32) (point * point - 17) * 0.875;
        z := cast(float32) (point * 3 - 11) * 7.25;
        Noise.domain_warp2_d(*state, *x, *y);
        add_sample(*digest, x);
        add_sample(*digest, y);
        Noise.domain_warp3_d(*state, *x, *y, *z);
        add_sample(*digest, x);
        add_sample(*digest, y);
        add_sample(*digest, z);
    }
    return digest;
}
