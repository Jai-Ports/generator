# Jai Ports generator

This repository reproducibly translates pinned C and C++ libraries into
standalone Jai module repositories.

## Setup

After cloning the repository, bootstrap its dependencies and generator:

```sh
./scripts/bootstrap.sh
```

Bootstrap is the one-time native setup step. It initializes the pinned toolbox
submodules, builds the Clang AST exporter used by the transpiler, and builds
`bin/generator`. Run it again after advancing the transpiler submodule when its
native host library changes.

After the host libraries are bootstrapped, rebuild the generator directly with:

```sh
jai-linux build.jai   # Linux
jai-macos build.jai   # macOS
jai.exe build.jai     # Windows
```

The build workspace adds `src/` to Jai's import path so toolbox dependencies
resolve through names such as `#import "tbx/arena"` and `#import "tbx/json"`.

## Workflow

Generate a port while developing it (developing here probably means improving the transpiler to produce better output):

```sh
./bin/generator xatlas
```

The generated module is written to its checkout under `out/`. When it is ready,
commit and push the generator inputs, regenerate it, and publish it:

Note: Generator inputs are not the generated module, instead they are changes made to the generator code 
while developing, and ported projects need a generator commit to point at.

```sh
./bin/generator xatlas
./bin/generator publish xatlas
git -C out/xatlas push
```

`publish` verifies the generator and generated module, then creates the output
commit locally. Pushing that commit remains explicit.

For available commands and options, run:

```sh
./bin/generator -h
```
