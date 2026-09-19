#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
transpiler_dir="$root_dir/src/tbx/transpiler"
host_libraries_dir="$transpiler_dir/host_libraries"

cd "$root_dir"

git -C "$root_dir" submodule update --init --recursive

"$host_libraries_dir/build_cpp_ast_exporter.sh"

case "$(uname -s)" in
    Linux*) jai_compiler="jai-linux" ;;
    Darwin*) jai_compiler="jai-macos" ;;
    CYGWIN*|MINGW*|MSYS*) jai_compiler="jai.exe" ;;
    *)
        printf 'error: unsupported host OS: %s\n' "$(uname -s)" >&2
        exit 1
        ;;
esac

"$jai_compiler" build.jai -quiet

printf 'Built %s/bin/generator\n' "$root_dir"
