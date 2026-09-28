#import "Basic";
Box :: #import "box3d";

main :: () {
    Box.initialize_program();
    definition: Box.World_Def;
    Box.default_world_def(*definition);
    world := Box.create_world(*definition);
    Box.world_step(world, 1.0 / 60.0, 4);
    Box.destroy_world(world);
    print("Box3D world lifecycle smoke verification passed\n");
}
