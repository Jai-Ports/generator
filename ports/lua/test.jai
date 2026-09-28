#import "Basic";
Lua :: #import "lua";

LUA_FIXTURE :: #string LUA_FIXTURE_TEXT
local sum = 0
for i = 1, 100 do sum = sum + i end
assert(sum == 5050 and -7 // 3 == -3 and -7 % 3 == 2)
assert((0xabcdef ~ 0x123456) == 0xb9f9b9)
local t = {5, 1, 9, 3}
table.sort(t)
assert(table.concat(t, ',') == '1,3,5,9')
local value = setmetatable({n = 7}, {__add = function(a, b) return a.n + b end})
assert(value + 4 == 11)
assert(string.gsub('a12 b34', '%d+', '#') == 'a# b#')
assert(utf8.len('Jai \226\152\131') == 5)
local co = coroutine.create(function(v) coroutine.yield(v + 1); return v + 2 end)
local ok, result = coroutine.resume(co, 40)
assert(ok and result == 41)
ok, result = coroutine.resume(co)
assert(ok and result == 42 and coroutine.status(co) == 'dead')
ok, result = pcall(function() error('expected failure') end)
assert(not ok and string.find(result, 'expected failure', 1, true))
local restored = assert(load(string.dump(function(x) return x * 3 end)))
assert(restored(14) == 42)
collectgarbage('collect')
return sum
LUA_FIXTURE_TEXT;

main :: () {
    Lua.initialize_program();
    state := Lua.l_newstate();
    assert(state != null);
    defer Lua.close(state);
    Lua.l_openselectedlibs(state, -1, 0);
    assert(Lua.l_loadbufferx(state, cast(*s8) LUA_FIXTURE.data, LUA_FIXTURE.count,
                           cast(*s8) temp_c_string("parity-fixture"), null) == 0);
    assert(Lua.pcallk(state, 0, 1, 0, 0, null) == 0);
    is_number: s32;
    assert(Lua.tointegerx(state, -1, *is_number) == 5050);
    assert(is_number == 1);
    Lua.settop(state, 0);
    assert(Lua.l_loadstring(state, cast(*s8) temp_c_string("return )")) != 0);
    Lua.settop(state, 0);
    print("lua parity fixture passed: 5050\n");
}
