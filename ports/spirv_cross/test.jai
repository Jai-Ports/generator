#import "Basic";
Spirv :: #import "spirv_cross";
main :: () {
    Spirv.initialize_program();
    major: u32;
    minor: u32;
    patch: u32;
    Spirv.get_version(*major, *minor, *patch);
    assert(major != 0 || minor != 0 || patch != 0);
    print("SPIRV-Cross version subset passed; shader translation/reflection, errors and performance remain required\n");
}
