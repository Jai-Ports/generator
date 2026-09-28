#import "Basic";
Library :: #import "implot";

// This is only a complete-source compilation/setup gate. Runtime parity is pending.
main :: () {
    Library.initialize_program();
    print("implot native module initialization passed\n");
}
