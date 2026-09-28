#import "Basic";
Audio :: #import "miniaudio";

main :: () {
    Audio.initialize_program();
    // Offline waveform tests are deliberately independent of sound hardware.
    // Device/backend coverage remains a separate acceptance requirement.
    config: Audio.Waveform_Config;
    Audio.waveform_config_init(*config, cast(Audio.Format) Audio.FORMAT_F32, 1, 48000,
                               cast(Audio.Waveform_Type) Audio.WAVEFORM_TYPE_SINE, 0.5, 12000.0);
    waveform: Audio.Waveform;
    assert(Audio.waveform_init(*config, *waveform) == 0);
    defer Audio.waveform_uninit(*waveform);
    frames: [8] float32;
    count: u64;
    assert(Audio.waveform_read_pcm_frames(*waveform, frames.data, frames.count, *count) == 0);
    assert(count == frames.count);
    expected := float32.[0, 0.5, 0, -0.5, 0, 0.5, 0, -0.5];
    for sample, index: frames {
        difference := sample - expected[index];
        assert(difference > -0.00001 && difference < 0.00001);
    }
    print("miniaudio offline waveform verification passed\n");
}
