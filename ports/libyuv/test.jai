#import "Basic";
Yuv :: #import "libyuv";

main :: () {
    Yuv.initialize_program();
    y := u8.[16, 16, 235, 235];
    u := u8.[128];
    v := u8.[128];
    rgba: [16] u8;
    assert(Yuv.I420ToARGB(y.data, 2, u.data, 1, v.data, 1, rgba.data, 8, 2, 2) == 0);
    for pixel: 0..3 {
        value := ifx pixel < 2 then cast(u8) 0 else cast(u8) 255;
        assert(rgba[pixel * 4] == value && rgba[pixel * 4 + 1] == value);
        assert(rgba[pixel * 4 + 2] == value && rgba[pixel * 4 + 3] == 255);
    }
}
