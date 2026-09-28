#import "Basic";
Shaderc :: #import "shaderc";

main :: () {
    Shaderc.initialize_program();
    compiler := Shaderc.compiler_initialize();
    assert(compiler != null);
    Shaderc.compiler_release(compiler);
    print("Shaderc compiler lifecycle subset passed; GLSL/HLSL, SPIRV and diagnostic parity remain required\n");
}
