#import "Basic";
Xatlas :: #import "xatlas";

main :: () {
    Xatlas.initialize_program();

    atlas: *Xatlas.Atlas = Xatlas.create();
    assert(atlas != null);

    positions := float32.[
        0.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        1.0, 1.0, 0.0,
        0.0, 1.0, 0.0,
    ];
    indices := u32.[0, 1, 2, 0, 2, 3];
    mesh: Xatlas.Mesh_Decl;
    mesh.vertex_position_data = cast(*void) positions.data;
    mesh.index_data = cast(*void) indices.data;
    mesh.vertex_count = 4;
    mesh.vertex_position_stride = cast(u32) (3 * size_of(float32));
    mesh.index_count = 6;
    mesh.index_format = Xatlas.INDEX_FORMAT_U_INT32;
    mesh.epsilon = 1.1920929e-07;
    assert(Xatlas.add_mesh(atlas, *mesh, 0) == Xatlas.ADD_MESH_ERROR_SUCCESS);

    chart_options: Xatlas.Chart_Options;
    Xatlas.init(*chart_options);
    pack_options: Xatlas.Pack_Options;
    Xatlas.init(*pack_options);
    assert(chart_options.max_iterations == 1);
    assert(pack_options.bilinear);
    pack_options.resolution = 64;
    pack_options.create_image = true;
    Xatlas.generate(atlas, chart_options, pack_options);
    assert(atlas.mesh_count == 1);
    assert(atlas.chart_count > 0);
    assert(atlas.width > 0 && atlas.height > 0);

    Xatlas.destroy(atlas);
    print("xatlas module verification passed\n");
}
