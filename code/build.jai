#import "Compiler";
#import "Basic";

build_release :: (workspace: Workspace)
{
    options   := get_build_options(workspace);
    copy_commonly_propagated_fields(get_build_options(), *options);

    options.output_executable_name           = "labyrinthian_DEBUG";
    options.output_type                      = .EXECUTABLE;
    options.output_path                      = "../build/";
    options.use_visual_studio_message_format = true;
    options.use_natvis_compatible_types      = true;
    options.dead_code_elimination            = .ALL;

    set_optimization(*options, .VERY_OPTIMIZED, false);
    set_build_options(options, workspace);

    compiler_begin_intercept(workspace);
    add_build_file("core_main.jai", workspace);
    compiler_end_intercept(workspace);

    set_build_options_dc(.{do_output=false});
}

build_debug :: (workspace: Workspace)
{
    options   := get_build_options(workspace);
    copy_commonly_propagated_fields(get_build_options(), *options);

    options.output_executable_name           = "labyrinthian_DEBUG";
    options.output_type                      = .EXECUTABLE;
    options.output_path                      = "../build/";
    options.use_visual_studio_message_format = false;
    options.use_natvis_compatible_types      = true;
    options.dead_code_elimination            = .NONE;
    options.enable_bytecode_inliner          = false;

    set_optimization(*options, .VERY_DEBUG);
    set_build_options(options, workspace);

    compiler_begin_intercept(workspace);
    add_build_file("core_main.jai", workspace);
    compiler_end_intercept(workspace);

    set_build_options_dc(.{do_output=false});
}

build :: ()
{
    workspace := compiler_create_workspace("Executable");
    options   := get_build_options(workspace);
    args      := options.compile_time_command_line;

    is_release := array_find(args, "-release");
    if is_release
    {
        build_release(workspace);
    }
    else
    {
        build_debug(workspace);
    }
}

#run build();
