#import "Basic";
Terminal :: #import "ftxui";

main :: () {
    // This gate establishes whole-library Jai compilation and global setup.
    // A Unicode/screen/input differential corpus is a separate required gate.
    Terminal.initialize_program();
    print("FTXUI whole-library compilation and initialization passed\n");
}
