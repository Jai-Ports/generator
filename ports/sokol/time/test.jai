#import "Basic";
Time :: #import "sokol/time";

main :: () {
    Time.initialize_program();
    Time.setup();
    // POSIX backend timestamps use nanosecond ticks.
    assert(Time.sec(1_000_000_000) == 1.0);
    assert(Time.ms(1_000_000) == 1.0);
    assert(Time.us(1_000) == 1.0);
    assert(Time.ns(7) == 7.0);
    assert(Time.diff(20, 7) == 13);
    assert(Time.diff(7, 20) == 1);
    before := Time.now();
    after := Time.now();
    assert(after >= before);
}
