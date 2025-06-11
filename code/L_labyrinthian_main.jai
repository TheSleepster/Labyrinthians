#import "Math";
#import "String";
#import "Atomics";
#import "File";
#import "File_Utilities";
#import "Random";
#import "Sort";
#import "Unicode";

#import "SDL";
#import "GL";
#import "freetype-2.12.1";


// Bitmap loading and saving:
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

L_labyrinthian_main :: ()
{
    window := SDL_CreateWindow("Labyrinthians",
                               SDL_WINDOWPOS_CENTERED,
                               SDL_WINDOWPOS_CENTERED,
                               1920,
                               1080,
                               SDL_WINDOW_OPENGL|SDL_WINDOW_SHOWN|SDL_WINDOW_RESIZABLE);
    if window
    {
        asset_manager := am_init();

        input_manager: Input_Manager;
        render_state := r_init_renderer_data(window, *asset_manager);

        font := asset_get_font(*asset_manager, "LiberationMono-Regular");

        is_running := true;
        while is_running
        {
            c_handle_input_events(*input_manager);

            //r_test_render(*render_state);
            r_render_group_test_render(*render_state, *asset_manager);
            SDL_GL_SwapWindow(window);

            reset_temporary_storage();
            r_reset_draw_frame(*render_state);
        }
    }
    else
    {
        log_error("[ERROR]: SDL_CreateWindow has failed with error: %...\n", SDL_GetError());
    }
}
