generator_print_help :: () {
    print(#string HELP
Jai Ports generator

Usage:
  generator list
  generator <port> [--offline]
  generator generate <port> [--offline]
  generator check <port> [--offline]
  generator publish <port> [--offline]

Commands:
  list       List available typed port recipes.
  generate   Build, verify, and synchronize development output.
  check      Build and verify, then fail if the output repository differs.
  publish    Require clean pushed inputs, verify, and commit generated output.

Options:
  --offline  Do not fetch upstream source; require its pinned commit locally.
             Publish still fetches Git remotes to verify pushed state.
HELP);
}

generator_cli_main :: () {
    command_line := get_command_line_arguments();
    if command_line.count < 2 {
        generator_print_help();
        return;
    }

    command := command_line[1];
    if command == "help" || command == "--help" || command == "-h" {
        generator_print_help();
        return;
    }
    if command == "list" {
        if command_line.count != 2 generator_error("list does not accept arguments");
        generator_list_ports();
        return;
    }
    port_name: string;
    option_start: int;
    if command == "generate" || command == "check" || command == "publish" {
        if command_line.count < 3 generator_error(tprint("% requires a port name", command));
        port_name = command_line[2];
        option_start = 3;
    } else {
        port, found := generator_find_port(command);
        if !found generator_error(tprint("unknown command or port: %", command));
        port_name = port.name;
        command = "generate";
        option_start = 2;
    }

    options: Generator_Options;
    for index: option_start..command_line.count-1 {
        argument := command_line[index];
        if argument == "--offline" options.offline = true;
        else generator_error(tprint("unknown option: %", argument));
    }

    if command == "generate" generator_generate(port_name, options);
    else if command == "check" generator_check(port_name, options);
    else generator_publish(port_name, options);
}
