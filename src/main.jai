#import "Basic";

#load "generator/arena_compat.jai";
#load "tbx/transpiler/cpp/module.jai";
#load "generator/types.jai";
#load "../ports/xatlas.jai";
#load "generator/pipeline.jai";
#load "generator/cli.jai";

main :: () {
    generator_cli_main();
}
