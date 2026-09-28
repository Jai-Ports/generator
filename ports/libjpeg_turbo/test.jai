#import "Basic";
Jpeg :: #import "libjpeg_turbo";

main :: () {
    Jpeg.initialize_program();
    encoder := Jpeg.tj3_init(Jpeg.TJINIT_COMPRESS);
    decoder := Jpeg.tj3_init(Jpeg.TJINIT_DECOMPRESS);
    assert(encoder != null && decoder != null);
    defer Jpeg.tj3_destroy(encoder);
    defer Jpeg.tj3_destroy(decoder);
    assert(Jpeg.tj3_set(encoder, Jpeg.TJPARAM_QUALITY, 95) == 0);
    assert(Jpeg.tj3_set(encoder, Jpeg.TJPARAM_SUBSAMP, Jpeg.TJSAMP_444) == 0);
    pixels: [16 * 16 * 3] u8;
    for *pixel: pixels pixel.* = 127;
    encoded: *u8;
    size: u64;
    assert(Jpeg.tj3_compress8(encoder, pixels.data, 16, 0, 16, Jpeg.TJPF_RGB, *encoded, *size) == 0);
    assert(encoded != null && size > 0);
    defer Jpeg.tj3_free(encoded);
    assert(Jpeg.tj3_decompress_header(decoder, encoded, size) == 0);
    assert(Jpeg.tj3_get(decoder, Jpeg.TJPARAM_JPEGWIDTH) == 16);
    assert(Jpeg.tj3_get(decoder, Jpeg.TJPARAM_JPEGHEIGHT) == 16);
    decoded: [16 * 16 * 3] u8;
    assert(Jpeg.tj3_decompress8(decoder, encoded, size, decoded.data, 0, Jpeg.TJPF_RGB) == 0);
    for value: decoded assert(value >= 126 && value <= 128);
    print("Portable JPEG encode/decode subset passed; SIMD and corpus parity remain required\n");
}
