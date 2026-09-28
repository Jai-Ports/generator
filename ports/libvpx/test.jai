#import "Basic";
Vpx :: #import "libvpx";
main :: () {
    Vpx.initialize_program();
    assert(Vpx.codec_version() > 0);
    print("libvpx version subset passed; codec, SIMD and malformed-stream parity remain required\n");
}
