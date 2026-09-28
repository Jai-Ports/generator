#import "Basic";
Noise :: #import "stb/perlin";

main :: () {
    Noise.initialize_program();
    assert(Noise.noise3(0, 0, 0, 0, 0, 0) == 0);
    for i: 0..100 {
        x := cast(float32) i * 0.125;
        a := Noise.noise3_seed(x, 0.25, -0.75, 8, 8, 8, 37);
        b := Noise.noise3_seed(x + 8, 0.25, -0.75, 8, 8, 8, 37);
        assert(a == b);
        assert(a >= -1 && a <= 1);
    }
    print("stb/perlin periodic noise verification passed\n");
}
