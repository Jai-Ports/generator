#import "Basic";
Navigation :: #import "recastnavigation";

main :: () {
    Navigation.initialize_program();
    minimum := float32.[0, 0, 0];
    maximum := float32.[4, 2, 6];
    width, depth: s32;
    Navigation.rc_calc_grid_size(minimum.data, maximum.data, 0.5, *width, *depth);
    assert(width == 8 && depth == 12);
    heightfield := Navigation.rc_alloc_heightfield();
    assert(heightfield != null);
    Navigation.rc_free_height_field(heightfield);
    print("Recast grid/allocation smoke verification passed\n");
}
