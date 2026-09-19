// The pinned transpiler requests a configurable arena region capacity, but
// jai-toolbox/arena@3893b9e does not yet publish that argument. Keep the
// dependency checkout clean and provide the narrow source-compatible overload
// here. Remove this shim once arena publishes its region-capacity change and
// the generator advances the submodule pin.
get_arena_allocator :: (region_capacity: s64) -> Allocator {
    assert(region_capacity > 0);
    return get_arena_allocator();
}

