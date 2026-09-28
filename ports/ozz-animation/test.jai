#import "Basic";
Library :: #import "ozz-animation";

// This is only a complete-source compilation/setup gate. Runtime parity is pending.
main :: () {
    Library.initialize_program();
    print("ozz-animation native module initialization passed\n");
}
