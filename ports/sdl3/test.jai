#import "Basic";
SDL :: #import "sdl3";

main :: () {
    SDL.initialize_program();
    assert(SDL.get_version() / 1000000 == 3);
    assert(SDL.init(0x00004000)); // SDL_INIT_EVENTS, from the pinned SDL header.
    defer SDL.quit();
    assert((SDL.was_init(0) & 0x00004000) != 0);
    first := SDL.get_ticks_ns();
    second := SDL.get_ticks_ns();
    assert(second >= first);
    print("SDL3 events/timer subset passed; device, graphics and window parity remains required\n");
}
