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
        texture    : Texture2D;
        sprite_data: Static_Sprite2D;
    };
};

Asset_Manager :: struct
{
    asset_allocator: *Zone_Allocator;
    hash_data_arena:  Memory_Arena;
    atlas_builder  :  Atlas_Builder;

    texture_hash   :  C_Hash_Table; 
    sprite_hash    :  C_Hash_Table;
};

am_init :: () -> Asset_Manager
{
    stbi_set_flip_vertically_on_load(1);
    
    result: Asset_Manager;
    result.asset_allocator = za_init(GB(1));
    result.hash_data_arena = c_arena_init(MB(100));
    result.texture_hash    = c_hash_table_create(*result.hash_data_arena, 512); 
    result.atlas_builder   = ab_init_atlas_builder(result.asset_allocator,
                                                   2048,
                                                   2048,
                                                  .FORMAT_RGBA);

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

        texture_data := *asset_slot.texture;
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
    data    :  *u8;
    channels:   u32;
    format  :   Bitmap_Format;
    
    stride  :   s32;
    width   :   s32;
    height  :   s32;

    is_dirty:   bool;
    is_valid:   bool;
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
};

asset_synchronous_load_texture_data :: inline (asset_slot: *Asset_Slot)
{
    asset_slot.slot_state = .LOADED;
    
    texture     := *asset_slot.texture;
    texture.bitmap.data = stbi_load(temp_c_string(texture.filepath),
                                   *texture.bitmap.width,
                                   *texture.bitmap.height,
                                xx *texture.bitmap.channels,
                                    0);
    texture.bitmap.is_valid = true;
    texture.bitmap.is_dirty = true;
}

asset_get_texture :: (asset_manager: *Asset_Manager, hash_name: string) -> *Texture2D
{
    result: *Texture2D;

    asset_slot := cast(*Asset_Slot)c_hash_get_value(*asset_manager.texture_hash, hash_name);
    if asset_slot
    {
        if !asset_slot.texture.bitmap.data
        {
            asset_synchronous_load_texture_data(asset_slot);
        }
        result = *asset_slot.texture;
    }
    else
    {
        log("[ERROR]: Unable to find a texture associated with key '%', are you sure this is the right key?...\n", hash_name);
    }

    return result;
}

// TODO(Sleepster): Hey, is this no-initial idea good? 
asset_create_texture_from_bitmap :: (bitmap     : Bitmap,
                                     has_AA     : bool,
                                     filter_type: Filter_Type,
                                     hash_name  : string = "",
                                     filepath   : string = "") -> Texture2D
{
    result: Texture2D = ---;
    result.bitmap      = bitmap;
    result.has_AA      = has_AA;
    result.filter_type = filter_type;
    result.hash_name   = hash_name;
    result.filepath    = filepath;
    result.texID       = 0;
    result.atlas_data  = null;

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
        texture := *texture_slot.texture;
        ab_add_texture_to_builder_atlas(asset_manager, *asset_manager.atlas_builder, texture, result);
    }
    else
    {
        log("[ERROR]: No texture with the name of '%' found in the texture hash...\n");
        assert(false);
    }
    
    return result;
}
