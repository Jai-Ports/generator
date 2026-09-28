#import "Basic";
Png :: #import "libpng";

main :: () {
    Png.initialize_program();
    encoded := u8.[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 2, 0, 0, 0, 2, 8, 6, 0, 0, 0, 114, 182, 13, 36, 0, 0, 0, 23, 73, 68, 65, 84, 120, 156, 99, 248, 207, 192, 240, 31, 8, 27, 24, 128, 180, 195, 255, 255, 255, 25, 0, 64, 24, 7, 186, 230, 253, 232, 100, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];
    expected := u8.[255, 0, 0, 255, 0, 255, 0, 128, 0, 0, 255, 64, 255, 255, 255, 0];
    image: Png.Image;
    image.version = 1;
    assert(Png.image_begin_read_from_memory(*image, encoded.data, cast(u64) encoded.count) != 0);
    defer Png.image_free(*image);
    assert(image.width == 2 && image.height == 2);
    image.format = 3; // PNG_FORMAT_RGBA, four 8-bit channels.
    actual: [16] u8;
    assert(Png.image_finish_read(*image, null, actual.data, 0, null) != 0);
    for i: 0..15 assert(actual[i] == expected[i]);
}
