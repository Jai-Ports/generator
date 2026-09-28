#import "Basic";
Args :: #import "sokol/args";

main :: () {
    Args.initialize_program();
    arguments := *u8.[
        "sokol-test".data, "width=640".data,
        "title='Jai port'".data, "fullscreen".data,
    ];
    config: Args.Desc;
    config.argc = cast(s32) arguments.count;
    config.argv = cast(**s8) arguments.data;
    Args.setup(*config);
    assert(Args.isvalid());
    assert(Args.equals(cast(*s8) "width".data, cast(*s8) "640".data));
    assert(Args.equals(cast(*s8) "title".data, cast(*s8) "Jai port".data));
    assert(Args.boolean(cast(*s8) "fullscreen".data));
    assert(!Args.exists(cast(*s8) "missing".data));
    assert(Args.num_args() == 3);
    Args.shutdown();
    assert(!Args.isvalid());
}
