#import "Basic";
Library :: #import "imgui-node-editor";

// This is only a complete-source compilation/setup gate. Runtime parity is pending.
main :: () {
    Library.initialize_program();
    print("imgui-node-editor native module initialization passed\n");
}
