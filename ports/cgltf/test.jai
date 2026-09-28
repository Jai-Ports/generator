#import "Basic";
Gltf :: #import "cgltf";

main :: () {
    Gltf.initialize_program();
    digest := verify_scenes();
    assert(digest == 5330889567635995539);
    print("PARITY cgltf %\n", digest);
    if array_find(get_command_line_arguments(), "--benchmark") {
        started := seconds_since_init();
        checksum: u64;
        for 0..999 checksum += verify_scenes();
        print("BENCH % %\n", seconds_since_init() - started, checksum);
    }
}

mix :: (digest: *u64, value: u64) {
    digest.* = (digest.* ^ value) * 1099511628211;
}

verify_scenes :: () -> u64 {
    documents := string.[
        "{\"asset\":{\"version\":\"2.0\"}}",
        "{\"asset\":{\"version\":\"2.0\"},\"nodes\":[{\"name\":\"parent\",\"translation\":[2,-3,5],\"scale\":[2,3,4],\"children\":[1]},{\"name\":\"child\",\"translation\":[1,2,3]}],\"scenes\":[{\"nodes\":[0]}],\"scene\":0}",
        "{\"asset\":{\"version\":\"2.0\"},\"buffers\":[{\"byteLength\":36,\"uri\":\"data:application/octet-stream;base64,AAAAAAAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAA\"}],\"bufferViews\":[{\"buffer\":0,\"byteLength\":36}],\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":3,\"type\":\"VEC3\",\"min\":[0,0,0],\"max\":[1,1,0]}],\"meshes\":[{\"primitives\":[{\"attributes\":{\"POSITION\":0}}]}],\"nodes\":[{\"mesh\":0}],\"scenes\":[{\"nodes\":[0]}],\"scene\":0}",
        "{\"asset\":{\"version\":\"2.0\"},\"materials\":[{\"name\":\"metal\",\"pbrMetallicRoughness\":{\"baseColorFactor\":[0.25,0.5,0.75,1],\"metallicFactor\":0.9,\"roughnessFactor\":0.125},\"alphaMode\":\"BLEND\",\"doubleSided\":true,\"extensions\":{\"KHR_materials_unlit\":{}}}],\"extensionsUsed\":[\"KHR_materials_unlit\"]}",
        "[]",
        "{\"asset\":",
        "{\"asset\":{\"version\":\"1.0\"}}",
        "",
        "{\"asset\":{\"version\":\"2.0\"},\"accessors\":[{\"bufferView\":99,\"componentType\":5126,\"count\":3,\"type\":\"VEC3\"}]}",
        "{\"asset\":{\"version\":\"2.0\"},\"nodes\":[{\"name\":\"hello \\\\ \\\" caf\\u00e9\"}]}",
    ];
    digest: u64 = 14695981039346656037;
    options: Gltf.Options;
    for document: documents {
        data: *Gltf.Data;
        result := Gltf.parse(*options, document.data, cast(u64) document.count, *data);
        mix(*digest, cast(u64) result);
        if result != 0 continue;
        defer Gltf.free_(data);
        mix(*digest, cast(u64) Gltf.validate(data));
        mix(*digest, cast(u64) Gltf.load_buffers(*options, data, null));
        mix(*digest, data.nodes_count);
        mix(*digest, data.meshes_count);
        for index: 0..cast(s64) data.nodes_count - 1 {
            matrix: [16] float32;
            Gltf.node_transform_local(*data.nodes[index], matrix.data);
            for value: matrix mix(*digest, (cast(*u32) *value).*);
        }
        for index: 0..cast(s64) data.accessors_count - 1 {
            accessor := *data.accessors[index];
            for element: 0..cast(s64) accessor.count - 1 {
                values: [16] float32;
                read := Gltf.accessor_read_float(accessor, cast(u64) element, values.data, 16);
                mix(*digest, cast(u64) read);
                for value: values mix(*digest, (cast(*u32) *value).*);
            }
        }
        buffer: [32768] s8;
        size := Gltf.write(*options, buffer.data, cast(u64) buffer.count, data);
        assert(size > 0 && size <= buffer.count);
        mix(*digest, size);
        for index: 0..cast(s64) size - 1 mix(*digest, cast,no_check(u8) buffer[index]);
    }
    return digest;
}
