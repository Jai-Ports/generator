OUTPUT_EXECUTABLE_NAME :: "generator";

Build_Mode :: enum {
    UNOPTIMIZED;
    OPTIMIZED;
}

#run {
    set_build_options_dc(.{do_output = false});

    build_mode := get_requested_build_optimization_mode();

    make_directory_if_it_does_not_exist("bin", recursive = true);

    workspace := compiler_create_workspace("Jai Ports Generator");
    options := get_build_options(workspace);
    copy_commonly_propagated_fields(get_build_options(), *options);
    options.output_executable_name = OUTPUT_EXECUTABLE_NAME;
    options.output_path = "bin/";
    apply_build_optimization_options(*options, build_mode);

    import_path: [..] string;
    array_add(*import_path, ..options.import_path);
    array_add(*import_path, "src/");
    options.import_path = import_path;

    set_build_options(options, workspace);
    add_build_file("src/main.jai", workspace);
}

get_requested_build_optimization_mode :: () -> Build_Mode {
    if command_line_has_flag("-optimized") || command_line_has_flag("-o")
        return .OPTIMIZED;
    return .UNOPTIMIZED;
}

command_line_has_flag :: (flag: string) -> bool {
    return array_find(get_toplevel_command_line(), flag);
}

apply_build_optimization_options :: (options: *Build_Options, mode: Build_Mode) {
    if mode != .OPTIMIZED return;

    set_optimization(options, .VERY_OPTIMIZED, preserve_debug_info = false);
    options.stack_trace = false;
    options.enable_frame_pointers = false;
    options.backtrace_on_crash = .OFF;
    options.array_bounds_check = .OFF;
    options.cast_bounds_check = .OFF;
    options.null_pointer_check = .OFF;
}

#import "Basic";
#import "Compiler";
#import "File";
