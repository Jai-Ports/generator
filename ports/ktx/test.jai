#import "Basic";
Ktx :: #import "ktx";

main :: () {
    Ktx.initialize_program();
    assert(Ktx.error_string(cast(Ktx.Error_Code) 0) != null);
    print("KTX error-string API subset passed; texture I/O, compression and upload parity remain required\n");
}
