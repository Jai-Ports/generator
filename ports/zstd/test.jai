#import "Basic";
Zstd :: #import "zstd";

main :: () {
    Zstd.initialize_program();
    input: [4096] u8;
    for *value, index: input value.* = cast(u8) ((index * 17 + index / 31) & 255);
    compressed: [8192] u8;
    count := Zstd.compress(compressed.data, compressed.count, input.data, input.count, 3);
    assert(Zstd.is_error(count) == 0);
    output: [4096] u8;
    restored := Zstd.decompress(output.data, output.count, compressed.data, count);
    assert(Zstd.is_error(restored) == 0 && restored == input.count);
    for value, index: input assert(output[index] == value);
    truncated := Zstd.decompress(output.data, output.count, compressed.data, 2);
    assert(Zstd.is_error(truncated) != 0);
    print("zstd roundtrip/error verification passed\n");
}
