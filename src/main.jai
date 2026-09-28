#import "Basic";

#load "generator/arena_compat.jai";
#load "tbx/transpiler/cpp/module.jai";
#load "generator/types.jai";
#load "generator/source_names.jai";
#load "../ports/registry.jai";
#load "generator/build_tools.jai";
#load "generator/pipeline.jai";
#load "generator/cli.jai";

main :: () {
    generator_cli_main();
}
