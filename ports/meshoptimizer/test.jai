#import "Basic";
Mesh :: #import "meshoptimizer";

main :: () {
    Mesh.initialize_program();
    assert(Mesh.quantizeHalf(0) == 0);
    assert(Mesh.quantizeHalf(1) == 0x3c00);
    assert(Mesh.quantizeHalf(-2) == 0xc000);
    assert(Mesh.dequantizeHalf(0x3c00) == 1);
    assert(Mesh.dequantizeHalf(0xc000) == -2);
    // Compile/run smoke checks only. The differential fixture and upstream suite
    // are separate gates; these assertions do not establish whole-library parity.
    print("meshoptimizer module smoke verification passed\n");
}
