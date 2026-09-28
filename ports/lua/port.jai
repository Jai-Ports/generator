lua_port :: () -> Port_Spec {
    return .{
        name = "lua",
        upstream_url = "https://github.com/lua/lua.git",
        upstream_commit = "0b29f408433e92953cc72b1d3e06c7ac8139e439",
        upstream_label = "upstream/lua",
        // Upstream embeds its MIT license in lua.h.
        license_file = "lua.h",
        language = .C,
        standard = "gnu99",
        include_directories = string.[],
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "lua",
            source_files = string.[
                "lapi.c", "lcode.c", "lctype.c", "ldebug.c", "ldo.c",
                "ldump.c", "lfunc.c", "lgc.c", "llex.c", "lmem.c",
                "lobject.c", "lopcodes.c", "lparser.c", "lstate.c",
                "lstring.c", "ltable.c", "ltm.c", "lundump.c", "lvm.c",
                "lzio.c", "lauxlib.c", "lbaselib.c", "ldblib.c",
                "liolib.c", "lmathlib.c", "loslib.c", "ltablib.c",
                "lstrlib.c", "lutf8lib.c", "loadlib.c", "lcorolib.c", "linit.c",
            ],
            // Upstream's portable switch backend; computed goto is a separate
            // unsupported profile and must be included in performance baselines.
            defines = string.["LUA_USE_LINUX", "LUA_USE_JUMPTABLE=0"],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/lua.git",
        supported_target = "linux-x64",
    };
}
