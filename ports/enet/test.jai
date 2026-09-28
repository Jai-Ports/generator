#import "Basic";
Enet :: #import "enet";

main :: () {
    Enet.initialize_program();
    assert(Enet.initialize() == 0);

    payload := u8.[1, 2, 3, 4];
    packet := Enet.packet_create(
        payload.data, cast(u64) payload.count, cast(u32) Enet.PACKET_FLAG_RELIABLE,
    );
    assert(packet != null);
    assert(packet.data_length == payload.count);
    Enet.packet_destroy(packet);

    verify_range_coder_roundtrip();

    assert(Enet.linked_version() != 0);
    Enet.deinitialize();
    print("enet module verification passed\n");
}

verify_range_coder_roundtrip :: () {
    input: [1024] u8;
    for *value, index: input
        value.* = cast(u8) ((index * 73 + index / 7) & 0xff);

    coder := Enet.range_coder_create();
    assert(coder != null);
    defer Enet.range_coder_destroy(coder);

    source := Enet.Buffer.{
        data = cast(*void) input.data,
        data_length = input.count,
    };
    compressed: [2048] u8;
    compressed_count := Enet.range_coder_compress(
        coder, *source, 1, input.count,
        compressed.data, compressed.count,
    );
    assert(compressed_count > 0);

    output: [1024] u8;
    output_count := Enet.range_coder_decompress(
        coder, compressed.data, compressed_count,
        output.data, output.count,
    );
    assert(output_count == input.count);
    for value, index: input assert(output[index] == value);
}
