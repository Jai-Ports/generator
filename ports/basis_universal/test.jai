#import "Basic";
Basis :: #import "basis_universal";
main :: () {
    Basis.initialize_program();
    assert(Basis.encoder_init(false, false));
    print("Basis encoder initialization subset passed; texture formats, transcode/encode corpus and performance remain required\n");
}
