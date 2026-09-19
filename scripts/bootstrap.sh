#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
transpiler_dir="$root_dir/src/tbx/transpiler"
host_libraries_dir="$transpiler_dir/host_libraries"

cd "$root_dir"

git -C "$root_dir" submodule update --init --recursive

# The transpiler's build is intentionally offline. Populate Cargo's cache
# first so a fresh machine can still use that reproducible build command.
cargo fetch --manifest-path "$host_libraries_dir/Cargo.toml" --locked
"$host_libraries_dir/build_regex_compat.sh"
"$host_libraries_dir/build_cpp_ast_exporter.sh"

jai build.jai -quiet

printf 'Built %s/bin/generator\n' "$root_dir"
