#import "Basic";
Ft :: #import "freetype";

main :: () {
    Ft.initialize_program();
    library: Ft.FT_Library;
    assert(Ft.ft_init_free_type(*library) == 0);
    assert(library != null);
    major, minor, patch: s32;
    Ft.ft_library_version(library, *major, *minor, *patch);
    assert(major == 2 && minor >= 0 && patch >= 0);
    assert(Ft.ft_done_free_type(library) == 0);
    print("FreeType initialization/version subset passed; font corpus remains required\n");
}
