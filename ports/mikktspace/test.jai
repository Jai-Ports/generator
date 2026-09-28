#import "Basic";
Mikk :: #import "mikktspace";

Mesh :: struct {
    mode: s32;
    quads: bool;
    salt: s32;
    digest: u64 = 14695981039346656037;
    callbacks: u64;
}

main :: () {
    Mikk.initialize_program();
    digest := verify_tangents();
    assert(digest == 7349294114768530969);
    print("PARITY mikktspace %\n", digest);
    if array_find(get_command_line_arguments(), "--benchmark") {
        started := seconds_since_init();
        checksum: u64;
        for salt: 0..19 checksum += verify_tangents(cast(s32) salt);
        print("BENCH % %\n", seconds_since_init() - started, checksum);
    }
}

mesh_data :: (ctx: *Mikk.S_Mikk_T_Space_Context) -> *Mesh {
    return cast(*Mesh) ctx.p_user_data;
}

get_num_faces :: (ctx: *Mikk.S_Mikk_T_Space_Context) -> s32 {
    return cast(s32) (ifx mesh_data(ctx).quads then 64 else 128);
}
get_num_vertices :: (ctx: *Mikk.S_Mikk_T_Space_Context, face: s32) -> s32 {
    return cast(s32) (ifx mesh_data(ctx).quads then 4 else 3);
}

get_corner :: (ctx: *Mikk.S_Mikk_T_Space_Context, face: s32, vertex: s32) -> (x: float32, y: float32) {
    mesh := mesh_data(ctx);
    corners := s32.[0, 1, 2, 0, 2, 3];
    corner := vertex;
    cell := face;
    if !mesh.quads {
        cell = face / 2;
        corner = corners[(face % 2) * 3 + vertex];
    }
    offsets_x := s32.[0, 1, 1, 0];
    offsets_y := s32.[0, 0, 1, 1];
    return cast(float32) (cell % 8 + offsets_x[corner]), cast(float32) (cell / 8 + offsets_y[corner]);
}
get_position :: (ctx: *Mikk.S_Mikk_T_Space_Context, out: *float32, face: s32, vertex: s32) {
    x, y := get_corner(ctx, face, vertex);
    if mesh_data(ctx).mode == 4 && face % 13 == 0 { x = 0; y = 0; }
    out[0] = x; out[1] = y; out[2] = 0;
}
get_normal :: (ctx: *Mikk.S_Mikk_T_Space_Context, out: *float32, face: s32, vertex: s32) {
    out[0] = 0; out[1] = 0; out[2] = 1;
}
get_tex_coord :: (ctx: *Mikk.S_Mikk_T_Space_Context, out: *float32, face: s32, vertex: s32) {
    x, y := get_corner(ctx, face, vertex);
    mesh := mesh_data(ctx);
    if mesh.mode == 1 x = -x;
    if mesh.mode == 2 { temporary := x; x = y; y = temporary; }
    if mesh.mode == 3 && face % 13 == 0 { x = 0; y = 0; }
    if mesh.mode == 5 { x *= cast(float32) (face % 3 + 1); y *= cast(float32) (face % 2 + 1); }
    out[0] = x + y * 0.25 + cast(float32) mesh.salt * 0.125;
    out[1] = y + x * 0.125;
}
mix_float :: (mesh: *Mesh, value: float32) {
    mesh.digest = (mesh.digest ^ cast(u64) (cast(*u32) *value).*) * 1099511628211;
}
set_tangent :: (ctx: *Mikk.S_Mikk_T_Space_Context, tangent: *float32, bitangent: *float32,
    magnitude_s: float32, magnitude_t: float32, orientation: s32, face: s32, vertex: s32) {
    mesh := mesh_data(ctx);
    for axis: 0..2 { mix_float(mesh, tangent[axis]); mix_float(mesh, bitangent[axis]); }
    mix_float(mesh, magnitude_s);
    mix_float(mesh, magnitude_t);
    mesh.digest = (mesh.digest ^ cast(u64) orientation) * 1099511628211;
    mesh.callbacks += 1;
}

verify_tangents :: (salt: s32 = 0) -> u64 {
    api := Mikk.S_Mikk_T_Space_Interface.{
        get_num_faces = get_num_faces, get_num_vertices_of_face = get_num_vertices,
        get_position = get_position, get_normal = get_normal, get_tex_coord = get_tex_coord,
        set_t_space = set_tangent,
    };
    mesh: Mesh;
    mesh.salt = salt;
    ctx := Mikk.S_Mikk_T_Space_Context.{p_interface = *api, p_user_data = *mesh};
    for mode: 0..5 for topology: 0..1 {
        mesh.mode = cast(s32) mode;
        mesh.quads = topology == 1;
        result := Mikk.gen_tang_space_default(*ctx);
        assert(result != 0);
        mesh.digest = (mesh.digest ^ cast(u64) result) * 1099511628211;
    }
    assert(mesh.callbacks == 3840);
    return mesh.digest;
}
