#import "Basic";
Tracy :: #import "tracy";
main :: () {
    Tracy.initialize_program();
    Tracy.set_thread_name(cast(*s8) temp_c_string("jai-port-verification"));
    print("Tracy client thread-name subset passed; capture interoperability, concurrency and overhead remain required\n");
}
