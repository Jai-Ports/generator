#import "Basic";
Webm :: #import "libwebm";

main :: () {
    Webm.initialize_program();
    // EBML boundary checks only; media mux/parse roundtrips remain required.
    assert(Webm.mkvmuxer_GetUIntSize(0) == 1);
    assert(Webm.mkvmuxer_GetUIntSize(255) == 1);
    assert(Webm.mkvmuxer_GetUIntSize(256) == 2);
    assert(Webm.mkvmuxer_GetCodedUIntSize(126) == 1);
    assert(Webm.mkvmuxer_GetCodedUIntSize(127) == 2);
    assert(Webm.mkvmuxer_GetCodedUIntSize(16382) == 2);
    assert(Webm.mkvmuxer_GetCodedUIntSize(16383) == 3);
    assert(Webm.mkvmuxer_GetIntSize(-128) == 1);
    assert(Webm.mkvmuxer_GetIntSize(128) == 2);
}
