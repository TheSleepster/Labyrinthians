#import "Math";
#import "String";
#import "Atomics";
#import "File";
#import "File_Utilities";
#import "Random";
#import "Sort";
#import "Unicode";
#import "Machine_X64";

#import "SDL";
#import "GL";
#import "freetype-2.12.1";
#import "stb_image";
#import "stb_image_write";
#import "stb_image_resize";

#load "core_input_api.jai";
#load "core_platform_api.jai";
#load "core_hash_table.jai";
#load "core_arena_allocator.jai";
#load "core_zone_allocator.jai";
#load "core_utils.jai";
#load "r_opengl.jai";
#load "r_shaders_file.jai";
#load "r_render_group.jai";
#load "r_primitive_rendering_interface.jai";
#load "a_asset.jai";
#load "a_atlas_builder.jai";
#load "d_profiling.jai";

global_window_data: App_Window_Data;

Time :: struct
{
    delta_time: float32;
};

App_Window_Data :: struct
{
    window             : *SDL_Window;
    old_window_size    :  iVector2;
    current_window_size:  iVector2;
}

L_labyrinthian_main :: ()
{
    global_window_data.window = SDL_CreateWindow("Labyrinthians",
                                                 SDL_WINDOWPOS_CENTERED,
                                                 SDL_WINDOWPOS_CENTERED,
                                                 1920,
                                                 1080,
                                                 SDL_WINDOW_OPENGL|SDL_WINDOW_ALLOW_HIGHDPI|SDL_WINDOW_SHOWN|SDL_WINDOW_RESIZABLE);
    if global_window_data.window
    {
        global_window_data.current_window_size = .{1920, 1080};
        
        performance_count_frequency := SDL_GetPerformanceFrequency();
        input_manager: Input_Manager;
        time         : Time;

        asset_manager := am_init();
        render_state  := r_init_renderer_data(global_window_data.window, *asset_manager);

        last_counter           := SDL_GetPerformanceCounter();
        last_cycle_counter     := rdtsc();

        is_running := true;
        while is_running
        {
            d_profile_scope();
            c_handle_window_events(*input_manager);

            //r_test_render(*render_state);
            r_render_group_test_render(*render_state, *asset_manager);
            SDL_GL_SwapWindow(global_window_data.window);

            reset_temporary_storage();
            r_reset_draw_frame(*render_state);

            end_cycle_counter     := rdtsc();
            delta_cycles          := end_cycle_counter - last_cycle_counter;
            mega_cycles_per_frame := cast(float32)delta_cycles / (1000.0 * 1000.0);

            end_counter    := SDL_GetPerformanceCounter();
            delta_counter  := end_counter - last_counter;
            time.delta_time = cast(float32)(cast(float64)delta_counter / cast(float64)performance_count_frequency);

            ms_per_frame   := cast(float64)((1000.0 * cast(float64)delta_counter) / cast(float64)performance_count_frequency);
            FPS            := performance_count_frequency / delta_counter;

            last_counter       = end_counter;
            last_cycle_counter = end_cycle_counter;

            // log("[INFO]: TIME INFORMATION:\nFRAME TIME: %ms\nFRAMES PER SECOND: %\nMEGA CYCLES PER FRAME: %...\n\n",
            //     ms_per_frame,
            //     FPS,
            //     mega_cycles_per_frame);

        }
    }
    else
    {
        log_error("[ERROR]: SDL_CreateWindow has failed with error: %...\n", SDL_GetError());
    }
}
