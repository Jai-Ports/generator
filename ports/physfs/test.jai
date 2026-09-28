#import "Basic";
Physfs :: #import "physfs";

main :: () {
    Physfs.initialize_program();
    assert(Physfs.init(cast(*s8) temp_c_string("jai-physfs-verification")) != 0);
    defer assert(Physfs.deinit() != 0);
    archive := u8.[
        80, 75, 3, 4, 20, 0, 0, 0, 0, 0, 0, 0, 33, 80, 26, 86,
        217, 106, 10, 0, 0, 0, 10, 0, 0, 0, 9, 0, 0, 0, 104, 101,
        108, 108, 111, 46, 116, 120, 116, 74, 97, 105, 32, 112, 97, 114, 105, 116,
        121, 80, 75, 1, 2, 20, 3, 20, 0, 0, 0, 0, 0, 0, 0, 33,
        80, 26, 86, 217, 106, 10, 0, 0, 0, 10, 0, 0, 0, 9, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 1, 0, 0, 0, 0, 104,
        101, 108, 108, 111, 46, 116, 120, 116, 80, 75, 5, 6, 0, 0, 0, 0,
        1, 0, 1, 0, 55, 0, 0, 0, 49, 0, 0, 0, 0, 0,
    ];
    assert(Physfs.mount_memory(archive.data, archive.count, null,
                              cast(*s8) temp_c_string("fixture.zip"),
                              cast(*s8) temp_c_string(""), 0) != 0);
    file := Physfs.open_read(cast(*s8) temp_c_string("hello.txt"));
    assert(file != null);
    bytes: [10] u8;
    assert(Physfs.read_bytes(file, bytes.data, bytes.count) == bytes.count);
    assert(Physfs.close(file) != 0);
    assert(string.{data = bytes.data, count = bytes.count} == "Jai parity");
    assert(Physfs.open_read(cast(*s8) temp_c_string("missing.txt")) == null);
    print("physfs ZIP/missing-file verification passed\n");
}
