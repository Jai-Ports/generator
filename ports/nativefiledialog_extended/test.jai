#import "Basic";
Nfd :: #import "nativefiledialog_extended";

main :: () {
    Nfd.initialize_program();
    // Dialogs require an interactive display session; this verifies generated
    // source integration and the error-state API without opening a dialog.
    Nfd.clear_error();
    assert(Nfd.get_error() == null);
    print("Native file dialog error-state subset passed; display interaction and portal parity remain required\n");
}
