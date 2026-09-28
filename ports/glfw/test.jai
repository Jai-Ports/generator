#import "Basic";
Glfw :: #import "glfw";

// Compile the complete Linux X11/Wayland source graph. This runtime fixture
// covers the null platform only; real display integration remains required.
main :: () {
    Glfw.initialize_program();
    major, minor, revision: s32;
    Glfw.get_version(*major, *minor, *revision);
    assert(major == 3 && minor >= 4 && revision >= 0);
    Glfw.init_hint(0x00050003, 0x00060005); // GLFW_PLATFORM, GLFW_PLATFORM_NULL
    assert(Glfw.init() != 0);
    defer Glfw.terminate();
    assert(Glfw.get_platform() == 0x00060005);
    assert(Glfw.get_timer_frequency() > 0);
    before := Glfw.get_timer_value();
    assert(Glfw.get_timer_value() >= before);
    Glfw.window_hint(0x00022001, 0); // GLFW_CLIENT_API, GLFW_NO_API
    window := Glfw.create_window(320, 180, cast(*s8) temp_c_string("Source port verification"), null, null);
    assert(window != null);
    defer Glfw.destroy_window(window);
    width, height: s32;
    Glfw.get_window_size(window, *width, *height);
    assert(width == 320 && height == 180);
    Glfw.set_window_size(window, 512, 288);
    Glfw.get_window_size(window, *width, *height);
    assert(width == 512 && height == 288);
    assert(Glfw.window_should_close(window) == 0);
    Glfw.set_window_should_close(window, 1);
    assert(Glfw.window_should_close(window) == 1);
    print("GLFW full Linux source compilation and null-platform subset passed\n");
}
