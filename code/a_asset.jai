Asset_Slot_State :: enum
{
    UNLOADED;
    QUEUED;
    LOADED;
};

Asset_Slot :: struct
{
    slot_state: Asset_Slot_State;
    union
    {
        texture_data   : Texture2D;
        sprite_data    : Static_Sprite2D;
        shader_data    : GPU_Shader;
        render_material: Render_Material;
    };
};

Asset_Manager :: struct
{
    asset_allocator      : *Zone_Allocator;
    hash_data_arena      :  Memory_Arena;
    permanent_asset_arena:  Memory_Arena;

    master_atlas_builder :  Atlas_Builder;
    texture_hash         :  C_Hash_Table; 
    shader_hash          :  C_Hash_Table;
    render_material_hash :  C_Hash_Table;
};

am_init :: () -> Asset_Manager
{
    stbi_set_flip_vertically_on_load(1);
    
    result: Asset_Manager;
    result.asset_allocator       = za_init(GB(1));
    result.hash_data_arena       = c_arena_init(MB(100));
    result.permanent_asset_arena = c_arena_init(MB(100));
    result.texture_hash          = c_hash_table_create(*result.hash_data_arena, 509); 
    result.shader_hash           = c_hash_table_create(*result.hash_data_arena, 257);
    result.render_material_hash  = c_hash_table_create(*result.hash_data_arena, 257);
    result.master_atlas_builder  = ab_init_atlas_builder(result.asset_allocator,
                                                         ENGINE_TEXTURE_SIZE,
                                                         ENGINE_TEXTURE_SIZE,
                                                        .FORMAT_RGBA,
                                                         true);

    if is_directory("../run_tree/res/textures")
    {
        visit_files("../run_tree/res/textures",
                    true,
                    cast(*void)*result,
                    am_prepare_texture_metadata,
                    true);
    }
    if is_directory("../run_tree/res/sounds")
    {
        // visit_files("../data/res/sounds",
        //             true,
        //             cast(*void)*result,
        //             asset_manager_prepare_sound_metadata,
        //             true);

    }
    if is_directory("../run_tree/res/fonts")
    {
        // visit_files("../data/res/fonts",
        //             true,
        //             cast(*void)*result,
        //             asset_manager_prepare_font_metadata,
        //             true);

    }

    asset_add_shader_to_hash(*result, BASIC_SHADER_SOURCE_TEXT, "Basic_Shader", .PIXEL);

    default_material: Render_Material;
    default_material.ambient_color  = .{1, 1, 1, 1};
    default_material.specular_color = .{1, 1, 1, 1};
    default_material.shine_color    = .{1, 1, 1, 1};

    default_material.ambient_strength  = 128.0;
    default_material.specular_strength = 128.0;
    default_material.shine_strength    = 128.0;
    asset_add_render_material_to_hash(*result, *default_material, "Default_Material");

    return result;
}

am_prepare_texture_metadata :: (info: *File_Visit_Info, user_data: *void)
{
    asset_manager       := cast(*Asset_Manager)user_data;
    path, basename, ext := path_decomp(info.full_name);
    if ext == "png" && !info.is_directory
    {
        asset_slot := c_arena_push_struct(*asset_manager.hash_data_arena, Asset_Slot);
        asset_slot.slot_state = .UNLOADED;

        texture_data := *asset_slot.texture_data;
        texture_data.filepath  = copy_string(info.full_name);
        texture_data.hash_name = copy_string(basename);

        c_hash_insert_pair(*asset_manager.texture_hash, texture_data.hash_name, cast(*void)asset_slot);
        print("TEXTURE LOADED...\n");
        print("PATH: %\n", path);
        print("NAME: %\n\n\n", basename);
    }
}

///////////////
// BITMAPS 
///////////////

Bitmap_Format :: enum
{
    // NOTE(Sleepster): these are the channel count     
    FORMAT_R    :: 1;
    FORMAT_B    :: 1;
    FORMAT_RGB  :: 3;
    FORMAT_BGR  :: 3;
    FORMAT_RGBA :: 4;
    FORMAT_BGRA :: 4;
};

Bitmap :: struct
{
    data    : *u8;
    channels:  s32;
    format  :  Bitmap_Format;
    
    stride  :  s32;
    width   :  s32;
    height  :  s32;

    is_dirty:  bool;
    is_valid:  bool;
};

asset_init_bitmap :: (zone: *Zone_Allocator, width: s32, height: s32, format: Bitmap_Format) -> Bitmap
{
    result: Bitmap;
    result.format   = format;
    result.width    = width;
    result.height   = height;
    result.stride   = xx (1 * xx result.format);
    result.data     = za_alloc(zone, size_of(u8) * (cast(u32)(result.width * result.height) * xx result.format), .STATIC);
    result.is_valid = true;
    result.channels = xx result.format;

    return result;
}

////////////////
// TEXTURES
////////////////

Filter_Type :: enum
{
    NEAREST;
    LINEAR;
};

Texture2D :: struct
{
    texID      :  u32;
    bitmap     :  Bitmap;

    filepath   :  string;
    hash_name  :  string;

    has_AA     :  bool        = false;
    filter_type:  Filter_Type = .NEAREST;

    // NOTE(Sleepster): will be null if this texture is not an atlas... 
    atlas_data : *Texture_Atlas_Data;
    is_in_atlas:  bool;
};

asset_synchronous_load_texture_data :: inline (asset_slot: *Asset_Slot)
{
    asset_slot.slot_state = .LOADED;
    
    texture     := *asset_slot.texture_data;
    texture.bitmap.data = stbi_load(temp_c_string(texture.filepath),
                                   *texture.bitmap.width,
                                   *texture.bitmap.height,
                                xx *texture.bitmap.channels,
                                    0);
    texture.bitmap.is_valid = true;
    texture.bitmap.is_dirty = true;
}

asset_load_texture_from_hash :: inline (asset_manager: *Asset_Manager, hash_name: string)
{
    asset_get_texture(asset_manager, hash_name);
}

asset_get_texture :: (asset_manager: *Asset_Manager, hash_name: string) -> *Texture2D
{
    result: *Texture2D;

    asset_slot := cast(*Asset_Slot)c_hash_get_value(*asset_manager.texture_hash, hash_name);
    if asset_slot
    {
        if !asset_slot.texture_data.bitmap.data
        {
            asset_synchronous_load_texture_data(asset_slot);
        }
        result = *asset_slot.texture_data;
    }
    else
    {
        log("[ERROR]: Unable to find a texture associated with key '%', are you sure this is the right key?...\n", hash_name);
    }

    return result;
}

asset_free_texture_bitmap_data :: (asset_manager: *Asset_Manager, hash_name: string)
{
    asset_slot := cast(*Asset_Slot)c_hash_get_value(*asset_manager.texture_hash, hash_name);
    if asset_slot
    {
        texture_data := *asset_slot.texture_data;
        if asset_slot.slot_state == .LOADED
        {
            assert(texture_data.bitmap.data != null);

            asset_slot.slot_state = .UNLOADED;
            za_free(asset_manager.asset_allocator, cast(**void)*texture_data.bitmap.data);

            texture_data.bitmap = .{};
        }
        else
        {
            log("[ERROR]: Attempted to free texture data that doesn't exist on key: '%'...\n", hash_name);
            assert(false);
        }
    }
    else
    {
        log("[ERROR]: Texture with key '%' is not a valid key...\n", hash_name);
        assert(false);
    }
}

// TODO(Sleepster): Hey, is this no-initialize idea good? 
asset_create_texture_from_bitmap :: (bitmap     : Bitmap,
                                     has_AA     : bool,
                                     filter_type: Filter_Type,
                                     hash_name  : string = "",
                                     filepath   : string = "") -> Texture2D
{
    result: Texture2D  = .{};
    result.bitmap      = bitmap;
    result.has_AA      = has_AA;
    result.filter_type = filter_type;
    result.hash_name   = hash_name;
    result.filepath    = filepath;

    return result;
}

//////////////////
// ATLAS SPRITES
//////////////////
 
// NOTE(Sleepster): A sprite is functionally identical to that of a
// texture, the only difference is that a sprite has been inserted into
// an atlas while textures are simply individual.
Static_Sprite2D :: struct
{
    atlas_offset  : iVector2;
    atlas_size    : iVector2;

    parent_texture: *Texture2D;
    atlas_texture : *Texture2D;
};

// NOTE(Sleepster): Once you call this function, you are committing
// to having this image as part of an atlas. It can still be
// accessed and used as an individual image though.
asset_get_sprite :: (asset_manager: *Asset_Manager, sprite_name: string, insert_into_atlas: bool = true) -> *Static_Sprite2D
{
    result: *Static_Sprite2D;
    texture_slot := cast(*Asset_Slot)c_hash_get_value(*asset_manager.texture_hash, sprite_name);
    if texture_slot
    {
        texture := *texture_slot.texture_data;
        if texture.is_in_atlas == false
        {
            result = ab_add_texture_to_builder_atlas(asset_manager, *asset_manager.master_atlas_builder, texture);
        }
        else
        {
            assert(asset_manager.master_atlas_builder.store_keys == true);

            sprite := c_hash_get_value(*asset_manager.master_atlas_builder.atlas_texture.atlas_data.sprite_hash, sprite_name);
            assert(sprite != null);

            result = sprite;
        }
    }
    else
    {
        log("[ERROR]: No texture with the name of '%' found in the texture hash...\n");
        assert(false);
    }
    
    return result;
}

////////////
// SHADERS
////////////

asset_add_shader_to_hash :: (asset_manager: *Asset_Manager, shader_source_string: string, hash_name: string, type: GPU_Shader_Type)
{
    asset_slot  := c_arena_push_struct(*asset_manager.hash_data_arena, Asset_Slot);
    shader_data := *asset_slot.shader_data;

    shader_data.shader_type   = type;
    shader_data.hash_name     = hash_name;
    shader_data.shader_source = shader_source_string;    

    c_hash_insert_pair(*asset_manager.shader_hash, hash_name, asset_slot);
}

asset_get_shader :: (asset_manager: *Asset_Manager, shader_name: string) -> *GPU_Shader
{
    result: *GPU_Shader;
    
    asset_slot := cast(*Asset_Slot)c_hash_get_value(*asset_manager.shader_hash, shader_name);
    if asset_slot != null
    {
        shader := *asset_slot.shader_data;
        if shader.program_id == 0
        {
            shader.* = compile_shader_source(*asset_manager.permanent_asset_arena, *shader.shader_source, shader.shader_type);
        }
        result = shader;
    }
    else
    {
        log("[ERROR]: Shader by the name of '%' was not found...\n", shader_name);
    }

    return result;
}

/////////////////////
// RENDER_MATERIALS
/////////////////////

Render_Material :: struct
{
    ambient_color     : Vector4;
    specular_color    : Vector4;
    shine_color       : Vector4;

    ambient_strength  : float32;
    specular_strength : float32;
    shine_strength    : float32;
    __padding         : float32;
}#no_padding;

Render_Material_Data :: struct 
{
    material_name: string;
    material     : Render_Material;
}

asset_add_render_material_to_hash :: inline (asset_manager: *Asset_Manager,
                                             material_data: *Render_Material,
                                             hash_name    : string)
{
    c_hash_insert_pair(*asset_manager.render_material_hash, hash_name, material_data);
}

asset_get_render_material :: (asset_manager: *Asset_Manager, hash_name: string) -> *Render_Material
{
    result: *Render_Material;
    asset_slot := cast(*Asset_Slot)c_hash_get_value(*asset_manager.render_material_hash, hash_name);
    if asset_slot
    {
        result = *asset_slot.render_material;
    }
    else
    {
        log("[ERROR]: A material by the name of '%' is not a valid entry...\n", hash_name);
    }

    return result;
}
