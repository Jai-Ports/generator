#import "Basic";
Image_Resize :: #import "stb/image_resize";

main :: () {
    Image_Resize.initialize_program();

    input: [2 * 2 * 4] u8;
    for pixel: 0..3 {
        input[pixel * 4 + 0] = 17;
        input[pixel * 4 + 1] = 34;
        input[pixel * 4 + 2] = 51;
        input[pixel * 4 + 3] = 255;
    }
    output: [4 * 4 * 4] u8;
    resized := Image_Resize.resize_uint8_linear(
        input.data, 2, 2, 2 * 4,
        output.data, 4, 4, 4 * 4,
        cast(Image_Resize.Pixel_Layout) Image_Resize.RGBA,
    );
    assert(resized == output.data);
    for pixel: 0..15 {
        assert(output[pixel * 4 + 0] == 17);
        assert(output[pixel * 4 + 1] == 34);
        assert(output[pixel * 4 + 2] == 51);
        assert(output[pixel * 4 + 3] == 255);
    }

    print("stb/image_resize module verification passed\n");
}
