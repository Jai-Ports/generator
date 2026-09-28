#import "Basic";
ImGui :: #import "imgui";

main :: () {
    ImGui.initialize_program();

    imgui_context := ImGui.create_context(null);
    assert(imgui_context != null);

    io := ImGui.get_io();
    io.ini_filename = null;
    io.display_size = .{x = 640, y = 480};
    io.delta_time = 1.0 / 60.0;

    pixels: *u8;
    texture_width: s32;
    texture_height: s32;
    bytes_per_pixel: s32;
    ImGui.get_tex_data_as_rgba32(
        io.fonts, *pixels, *texture_width, *texture_height, *bytes_per_pixel,
    );
    assert(pixels != null);
    assert(texture_width > 0 && texture_height > 0);
    assert(bytes_per_pixel == 4);

    ImGui.new_frame();
    ImGui.begin(ImGui.c_string("Generator verification"), null, 0);
    button_size: ImGui.Im_Vec2;
    ImGui.Button(ImGui.c_string("Generated button"), *button_size);
    ImGui.end();
    ImGui.render();

    draw_data := ImGui.get_draw_data();
    assert(draw_data != null);
    assert(draw_data.valid);

    ImGui.destroy_context(imgui_context);
    print("imgui module verification passed\n");
}
