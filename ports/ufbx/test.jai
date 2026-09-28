#import "Basic";
#import "File";
Ufbx :: #import "ufbx";
fixture_bytes: [..] string;
dump_cases: bool;
fixture_names :: string.["maya_cube_6100_ascii.fbx", "maya_cube_6100_binary.fbx", "maya_cube_7500_ascii.fbx", "maya_cube_7500_binary.fbx", "blender_272_cube_7400_binary.fbx", "max2009_cube_anim_5800_ascii.fbx", "max2009_cube_anim_5800_binary.fbx", "maya_blend_shape_cube_6100_ascii.fbx", "maya_pivots_7500_ascii.fbx", "maya_transformed_skin_6100_ascii.fbx", "maya_transformed_skin_6100_binary.fbx", "maya_anim_layers_7500_ascii.fbx", "blender_282_suzanne_7400_binary.fbx", "blender_279_nested_meshes_7400_binary.fbx", "blender_293_half_skinned_7400_binary.fbx", "maya_instanced_skin_7700_binary.fbx", "maya_transformed_skin_7700_ascii.fbx", "maya_advanced_skinned_pivot_7700_binary.fbx", "maya_blend_shape_cube_7700_binary.fbx", "max_geometry_transform_instances_7700_binary.fbx", "max_instanced_material_7700_ascii.fbx", "motionbuilder_lights_7700_ascii.fbx", "maya_camera_light_axes_y_up_7700_binary.fbx", "synthetic_unicode_7500_binary.fbx", "maya_unicode_7400_binary.fbx", "maya_nurbs_curve_multiplicity_6100_binary.fbx", "maya_nurbs_surface_sphere_6100_binary.fbx", "maya_nurbs_surface_sphere_7500_ascii.fbx"];
scene_text :: "o Mesh\nv 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nvt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\nvn 0 0 1\nf 1/1/1 2/2/1 3/3/1\nf -4/1/1 -2/3/1 -1/4/1\n";
main :: () {
    Ufbx.initialize_program();
    // Anonymous C records expose their original public members in Jai.
    vector: Ufbx.Vec3;
    vector.x = 1; vector.y = 2; vector.z = 3;
    assert(vector.v[0] == 1 && vector.v[1] == 2 && vector.v[2] == 3);
    matrix: Ufbx.Matrix;
    matrix.m03 = 7;
    assert(matrix.cols[3].x == 7 && matrix.v[9] == 7);
    arguments := get_command_line_arguments();
    dump_cases = array_find(arguments, "--dump");
    for argument, index: arguments {
        if argument == "--fixtures" {
            assert(index + 1 < arguments.count);
            for name: fixture_names {
                bytes, ok := read_entire_file(tprint("%/%", arguments[index + 1], name));
                assert(ok);
                array_add(*fixture_bytes, bytes);
            }
        }
    }
    defer {
        for bytes: fixture_bytes free(bytes);
        array_free(fixture_bytes);
    }
    digest := verify_scene();
    print("PARITY ufbx %\n", digest);
    if array_find(get_command_line_arguments(), "--benchmark") {
        started := seconds_since_init();
        checksum: u64;
        for 0..19 checksum += verify_scene();
        print("BENCH % %\n", seconds_since_init() - started, checksum);
    }
}
mix :: (digest: *u64, value: u64) { digest.* = (digest.* ^ value) * 1099511628211; }
verify_scene :: () -> u64 {
    options: Ufbx.Load_Opts;
    options.file_format = cast(u32) Ufbx.FILE_FORMAT_OBJ;
    error: Ufbx.Error;
    scene := Ufbx.load_memory(cast(*void) scene_text.data, cast(u64) scene_text.count, *options, *error);
    if scene == null {
        message: [2048] s8;
        Ufbx.format_error(message.data, cast(u64) message.count, *error);
        print("ufbx load error %: %\n", error.type, to_string(cast(*u8) message.data));
    }
    assert(scene != null);
    defer Ufbx.free_scene(scene);
    node := Ufbx.find_node(scene, Ufbx.c_string("Mesh"));
    assert(node != null && node.mesh != null);
    mesh := node.mesh;
    assert(mesh.num_vertices == 4 && mesh.num_faces == 2 && mesh.num_indices == 6);
    digest: u64 = 14695981039346656037;
    mix(*digest, mesh.num_vertices); mix(*digest, mesh.num_faces); mix(*digest, mesh.num_indices);
    for index: 0..cast(s64) mesh.vertices.count - 1 {
        values := mesh.vertices.data[index].v;
        for axis: 0..2 mix(*digest, (cast(*u64) *values[axis]).*);
    }
    for index: 0..cast(s64) mesh.vertex_indices.count - 1 mix(*digest, mesh.vertex_indices.data[index]);
    for bytes, index: fixture_bytes {
        if dump_cases print("LOAD %\n", fixture_names[index]);
        verify_fbx(bytes, *digest);
        if dump_cases print("CASE % %\n", fixture_names[index], digest);
    }
    return digest;
}

verify_fbx :: (bytes: string, digest: *u64) {
    options: Ufbx.Load_Opts;
    options.file_format = cast(u32) Ufbx.FILE_FORMAT_FBX;
    error: Ufbx.Error;
    scene := Ufbx.load_memory(cast(*void) bytes.data, cast(u64) bytes.count, *options, *error);
    if scene == null {
        message: [2048] s8;
        Ufbx.format_error(message.data, cast(u64) message.count, *error);
        print("FBX load error %: %\n", error.type, to_string(cast(*u8) message.data));
    }
    assert(scene != null);
    defer Ufbx.free_scene(scene);
    assert(scene.nodes.count > 0);
    mix(digest, scene.elements.count);
    for index: 0..cast(s64) scene.elements.count - 1 {
        element := scene.elements.data[index];
        mix(digest, element.type);
        mix(digest, element.name.length);
        for ch: 0..cast(s64) element.name.length - 1
            mix(digest, cast,no_check(u8) element.name.data[ch]);
        mix(digest, element.props.props.count);
        for pi: 0..cast(s64) element.props.props.count - 1 {
            property := *element.props.props.data[pi];
            mix(digest, property.name.length); mix(digest, property.type); mix(digest, property.flags);
            for ch: 0..cast(s64) property.name.length - 1
                mix(digest, cast,no_check(u8) property.name.data[ch]);
            if (property.flags & cast(u32) Ufbx.PROP_FLAG_VALUE_INT) != 0
                mix(digest, cast,no_check(u64) property.value_int);
            if (property.flags & cast(u32) Ufbx.PROP_FLAG_VALUE_STR) != 0 {
                mix(digest, property.value_str.length);
                for ch: 0..cast(s64) property.value_str.length - 1
                    mix(digest, cast,no_check(u8) property.value_str.data[ch]);
            }
            if (property.flags & cast(u32) Ufbx.PROP_FLAG_VALUE_BLOB) != 0 {
                mix(digest, property.value_blob.size);
                blob := cast(*u8) property.value_blob.data;
                for ch: 0..cast(s64) property.value_blob.size - 1 mix(digest, blob[ch]);
            }
            if (property.flags & cast(u32) Ufbx.PROP_FLAG_VALUE_REAL) != 0 {
                value := Ufbx.find_real_len(*element.props, property.name.data, property.name.length, 0);
                mix(digest, (cast(*u64) *value).*);
            }
            if (property.flags & cast(u32) Ufbx.PROP_FLAG_VALUE_VEC3) != 0 {
                zero, value: Ufbx.Vec3;
                Ufbx.find_vec3_len(*value, *element.props, property.name.data, property.name.length, zero);
                values := value.v;
                for axis: 0..2 mix(digest, (cast(*u64) *values[axis]).*);
            }
        }
        if element.type == cast(u32) Ufbx.ELEMENT_NODE {
            node := cast(*Ufbx.Node) element;
            mix(digest, node.children.count);
            mix(digest, cast(u64) node.visible);
            matrix := node.node_to_world.v;
            for axis: 0..11 mix(digest, (cast(*u64) *matrix[axis]).*);
        }
        if element.type == cast(u32) Ufbx.ELEMENT_MESH {
            mesh := cast(*Ufbx.Mesh) element;
            mix(digest, mesh.num_vertices); mix(digest, mesh.num_faces); mix(digest, mesh.num_indices);
            for vertex: 0..cast(s64) mesh.vertices.count - 1 {
                values := mesh.vertices.data[vertex].v;
                for axis: 0..2 mix(digest, (cast(*u64) *values[axis]).*);
            }
            for vi: 0..cast(s64) mesh.vertex_indices.count - 1 mix(digest, mesh.vertex_indices.data[vi]);
            for fi: 0..cast(s64) mesh.faces.count - 1 {
                mix(digest, mesh.faces.data[fi].index_begin);
                mix(digest, mesh.faces.data[fi].num_indices);
            }
        }
    }
}
