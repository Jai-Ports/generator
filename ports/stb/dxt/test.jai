#import "Basic";
Dxt :: #import "stb/dxt";

main :: () {
    Dxt.initialize_program();
    pixels: [64] u8;
    for i: 0..15 {
        pixels[i * 4] = cast(u8) (i * 17);
        pixels[i * 4 + 1] = cast(u8) (255 - i * 17);
        pixels[i * 4 + 2] = 127;
        pixels[i * 4 + 3] = cast(u8) (i * 17);
    }
    bc1: [8] u8;
    bc3, repeated: [16] u8;
    Dxt.compress_dxt_block(bc1.data, pixels.data, 0, 0);
    Dxt.compress_dxt_block(bc3.data, pixels.data, 1, 2);
    Dxt.compress_dxt_block(repeated.data, pixels.data, 1, 2);
    nonzero := false;
    for value, i: bc3 {
        assert(value == repeated[i]);
        if value != 0 nonzero = true;
    }
    assert(nonzero);
    print("stb/dxt compression verification passed\n");
}
