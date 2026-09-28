#import "Basic";
Image :: #import "stb/image";

main :: () {
    Image.initialize_program();

    // A 2x1 binary PPM containing red and green pixels.
    encoded := u8.[
        80, 54, 10,
        50, 32, 49, 10,
        50, 53, 53, 10,
        255, 0, 0,
        0, 255, 0,
    ];
    width: s32;
    height: s32;
    source_channels: s32;
    pixels := Image.load_from_memory(
        encoded.data, cast(s32) encoded.count,
        *width, *height, *source_channels, Image.RGB,
    );
    assert(pixels != null);
    defer Image.image_free(pixels);
    assert(width == 2 && height == 1 && source_channels == 3);
    assert(pixels[0] == 255 && pixels[1] == 0 && pixels[2] == 0);
    assert(pixels[3] == 0 && pixels[4] == 255 && pixels[5] == 0);

    print("stb/image module verification passed\n");
}
