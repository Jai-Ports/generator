#import "Basic";
Bgfx :: #import "bgfx";
main :: () {
    Bgfx.initialize_program();
    assert(Bgfx.get_supported_renderers(0, null) > 0);
    print("bgfx renderer inventory subset passed; rendering and backend parity remain required\n");
}
