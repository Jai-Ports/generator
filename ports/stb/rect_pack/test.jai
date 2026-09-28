#import "Basic";
Pack :: #import "stb/rect_pack";

main :: () {
    Pack.initialize_program();
    packing: Pack.Context;
    nodes: [32] Pack.Node;
    Pack.init_target(*packing, 32, 32, nodes.data, cast(s32) nodes.count);
    rectangles: [4] Pack.Rect;
    for *rectangle, i: rectangles {
        rectangle.id = cast(s32) i;
        rectangle.w = 16;
        rectangle.h = 16;
    }
    assert(Pack.pack_rects(*packing, rectangles.data, cast(s32) rectangles.count) != 0);
    for rectangle, i: rectangles {
        assert(rectangle.was_packed != 0);
        assert(rectangle.x >= 0 && rectangle.y >= 0);
        assert(rectangle.x + rectangle.w <= 32 && rectangle.y + rectangle.h <= 32);
        for other, j: rectangles {
            if i == j continue;
            assert(rectangle.x + rectangle.w <= other.x || other.x + other.w <= rectangle.x ||
                   rectangle.y + rectangle.h <= other.y || other.y + other.h <= rectangle.y);
        }
    }
    print("stb/rect_pack placement verification passed\n");
}
