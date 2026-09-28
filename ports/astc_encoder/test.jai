#import "Basic";
Astc :: #import "astc_encoder";
main :: () {
    Astc.initialize_program();
    config: Astc.Config;
    error := Astc.config_init(cast(Astc.Profile) 1, 4, 4, 1, 10.0, 0, *config);
    assert(cast(s32) error == 0);
    print("ASTC configuration subset passed; LDR/HDR encode/decode, ISA and performance parity remain required\n");
}
