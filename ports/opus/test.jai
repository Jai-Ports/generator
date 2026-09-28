#import "Basic";
Opus :: #import "opus";

main :: () {
    Opus.initialize_program();

    sample_rate :: 48000;
    frame_size :: sample_rate / 50; // 20 ms
    application_audio :: 2049;

    error: s32;
    encoder: *Opus.Encoder = Opus.encoder_create(
        sample_rate, 1, application_audio, *error,
    );
    assert(error == 0);
    assert(encoder != null);
    defer Opus.encoder_destroy(encoder);

    decoder: *Opus.Decoder = Opus.decoder_create(sample_rate, 1, *error);
    assert(error == 0);
    assert(decoder != null);
    defer Opus.decoder_destroy(decoder);

    input: [frame_size] s16;
    for *sample, index: input
        sample.* = cast(s16) ((index * 97) % 12000 - 6000);

    packet: [4000] u8;
    encoded_bytes := Opus.encode(
        encoder, input.data, frame_size, packet.data, packet.count,
    );
    assert(encoded_bytes > 0);

    decoded: [frame_size] s16;
    decoded_samples := Opus.decode(
        decoder, packet.data, encoded_bytes, decoded.data, frame_size, 0,
    );
    assert(decoded_samples == frame_size);

    output_is_not_silent := false;
    for sample: decoded {
        if sample != 0 {
            output_is_not_silent = true;
            break;
        }
    }
    assert(output_is_not_silent);
    assert(Opus.get_version_string() != null);
    print("opus module verification passed\n");
}
