#import "Basic";
Curl :: #import "curl";

main :: () {
    Curl.initialize_program();
    assert(Curl.version() != null);
    assert(Curl.global_init(3) == 0); // CURL_GLOBAL_ALL in the pinned header.
    defer Curl.global_cleanup();
    handle := Curl.easy_init();
    assert(handle != null);
    Curl.easy_cleanup(handle);
    print("libcurl lifecycle subset passed; protocol, TLS, error and concurrency parity remains required\n");
}
