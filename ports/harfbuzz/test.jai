#import "Basic";
HarfBuzz :: #import "harfbuzz";
main :: () {
    HarfBuzz.initialize_program();
    assert(HarfBuzz.version_string() != null);
    buffer := HarfBuzz.buffer_create();
    assert(buffer != null);
    defer HarfBuzz.buffer_destroy(buffer);
    HarfBuzz.buffer_add_utf8(buffer, cast(*s8) temp_c_string("abc"), 3, 0, 3);
    assert(HarfBuzz.buffer_get_length(buffer) == 3);
    print("HarfBuzz buffer subset passed; shaping, subset/raster/GPU corpus and performance remain required\n");
}
