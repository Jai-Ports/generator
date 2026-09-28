#import "Basic";
Gns :: #import "gamenetworkingsockets";

main :: () {
    Gns.initialize_program();
    error: [1024] u8;
    assert(Gns.init(null, *error));
    Gns.kill();
    print("GameNetworkingSockets lifecycle subset passed; reliability, crypto, ICE and concurrency parity remain required\n");
}
