#import "Math";
#import "String";
#import "Atomics";
#import "File";
#import "File_Utilities";
#import "Random";
#import "Sort";

#import "SDL";
#import "GL";

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
        render_state  := r_init_renderer_data(window);

        zone_allocator := za_init(MB(500));
        za_print_block_list(zone_allocator);
        za_validate_block_list(zone_allocator);

        memory  := za_alloc(zone_allocator, MB(330), .CACHED);
        za_print_block_list(zone_allocator);
        za_validate_block_list(zone_allocator);

        memory2 := za_alloc(zone_allocator, MB(120),  .CACHED);
        za_print_block_list(zone_allocator);
        za_validate_block_list(zone_allocator);

        memory3 := za_alloc(zone_allocator, MB(300),  .STATIC);
        za_print_block_list(zone_allocator);
        za_validate_block_list(zone_allocator);

        memory4 := za_alloc(zone_allocator, MB(180),  .STATIC);
        za_print_block_list(zone_allocator);
        za_validate_block_list(zone_allocator);

        za_free(zone_allocator, *memory4);
        za_print_block_list(zone_allocator);
        za_validate_block_list(zone_allocator);

        za_deinit(*zone_allocator);

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

// typedef struct vertex_t
// {
//     vec2 NDC_Position;
//     vec2 TexelCoords;
//     vec4 RenderColor;

//     int MaterialIndex;
//     int TextureIndex;
// }vertex;

// typedef struct render_material_t
// {
//     float Reflectivity;
//     float Opacity;
//     float IlluminationValue;
// }render_material;

// typedef enum primitive_type_t
// {
//     QUAD,
//     TRIANGLE,
//     LINE,
// }primitive_type;

// typedef struct render_quad_t
// {
//     union
//     {
//         vertex Elements[4];
//         struct
//         {
//             vertex TopLeft;
//             vertex TopRight;
//             vertex BottomLeft;
//             vertex TopLeft;
//         };
//     };

//     primitive_type Type;
    
//     vec2 WorldPosition;
//     vec2 TexelData;
//     vec4 RenderColor;

//     uint32 RequiredTexture;
//     uint32 BoundTextureIndex;
//     uint32 RenderLayer;
// }render_quad;


