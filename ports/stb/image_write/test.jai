#import "Basic";
Image_Write :: #import "stb/image_write";

main :: () {
    Image_Write.initialize_program();

    pixels := u8.[
        255, 0, 0,    0, 255, 0,
        0, 0, 255,    255, 255, 255,
    ];
    encoded_count: s32;
    encoded := Image_Write.png_to_mem(
        pixels.data, 2 * 3, 2, 2, 3, *encoded_count,
    );
    assert(encoded != null);
    defer Image_Write.c_transpiler_deallocate_memory(encoded);
    assert(encoded_count > 8);
    png_signature := u8.[137, 80, 78, 71, 13, 10, 26, 10];
    for expected, index: png_signature assert(encoded[index] == expected);

    print("stb/image_write module verification passed\n");
}
