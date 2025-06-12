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
        font_data      : Dynamic_Render_Font;
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
    render_font_hash     :  C_Hash_Table;
};

am_init :: () -> Asset_Manager
{
    stbi_set_flip_vertically_on_load(1);
    error := FT_Init_FreeType(*ft_library);
    assert(!error);
    
    result: Asset_Manager;
    result.asset_allocator       = za_init(GB(1));
    result.hash_data_arena       = c_arena_init(MB(100));
    result.permanent_asset_arena = c_arena_init(MB(100));
    result.texture_hash          = c_hash_table_create(*result.hash_data_arena, 509); 
    result.shader_hash           = c_hash_table_create(*result.hash_data_arena, 257);
    result.render_material_hash  = c_hash_table_create(*result.hash_data_arena, 257);
    result.render_font_hash      = c_hash_table_create(*result.hash_data_arena, 257);
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
        // visit_files("../run_tree/res/sounds",
        //             true,
        //             cast(*void)*result,
        //             asset_manager_prepare_sound_metadata,
        //             true);

    }
    if is_directory("../run_tree/res/fonts")
    {
        visit_files("../run_tree/res/fonts",
                    true,
                    cast(*void)*result,
                    am_prepare_font_metadata,
                    true);
    }

    asset_add_shader_to_hash(*result, BASIC_SHADER_SOURCE_TEXT, "Basic_Shader", .PIXEL);

    default_material: *Render_Material = c_arena_push_struct(*result.permanent_asset_arena, Render_Material);
    default_material.ambient_color  = .{1, 1, 1, 1};
    default_material.specular_color = .{1, 1, 1, 1};
    default_material.shine_color    = .{1, 1, 1, 1};

    default_material.ambient_strength  = 128.0;
    default_material.specular_strength = 128.0;
    default_material.shine_strength    = 128.0;
    asset_add_render_material_to_hash(*result, default_material, "Default_Material");

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

am_prepare_font_metadata :: (info: *File_Visit_Info, user_data: *void)
{
    asset_manager       := cast(*Asset_Manager)user_data;
    path, basename, ext := path_decomp(info.full_name);
    if ext == "ttf" && !info.is_directory
    {
        asset_slot := c_arena_push_struct(*asset_manager.hash_data_arena, Asset_Slot);
        asset_slot.slot_state = .UNLOADED;

        font_data := *asset_slot.font_data;
        font_data.filepath  = copy_string(info.full_name);
        font_data.font_name = copy_string(basename);

        c_hash_insert_pair(*asset_manager.render_font_hash, font_data.font_name, cast(*void)asset_slot);
        print("FONT LOADED...\n");
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

asset_init_bitmap_arena :: (arena: *Memory_Arena, width: s32, height: s32, format: Bitmap_Format) -> Bitmap
{
    result: Bitmap;
    result.format   = format;
    result.width    = width;
    result.height   = height;
    result.stride   = xx (1 * xx result.format);
    result.data     = c_arena_push_size(arena, (size_of(u8) * ((width * height) * xx format)));
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

//////////////
// FONT DATA
//////////////

Font_Glyph_Data :: struct
{
    glyph_data : Static_Sprite2D;
    glyph_key  : u32;

    offset_x   : s32;
    offset_y   : s32;
    advance    : s32;
    ascent     : s32;

    owner_page : *Dynamic_Render_Font_Page;
};

Dynamic_Render_Font_Page :: struct
{
    page_full       : bool;
    page_dirty      : bool;

    glyph_lookup    : C_Hash_Table;
    texture_data    : Texture2D;

    bitmap_cursor_x : s32;
    bitmap_cursor_y : s32;

    parent_varient  : *Dynamic_Render_Font_Varient;
    next_page       : *Dynamic_Render_Font_Page;
};

Dynamic_Render_Font_Varient :: struct
{
    pixel_size        : s32;

    character_height  : int;
    line_spacing      : int;
    max_ascender      : int;
    max_descender     : int;
    y_center_offset   : int;
    typical_ascender  : int;
    typical_descender : int;
    em_width          : int;

    default_unknown_character :  u32;
    utf32_unknown_character   := 0xfffd;

    parent_font : *Dynamic_Render_Font;
    first_page  : *Dynamic_Render_Font_Page;
};

Dynamic_Render_Font :: struct
{
    font_face     :  FT_Face;
    font_name     :  string;
    filepath      :  string;
    raw_font_data :  string;

    font_arena    :  Memory_Arena;
    pixel_sizes   :  [..]Dynamic_Render_Font_Varient;
};

set_unknown_character :: (font_varient: *Dynamic_Render_Font_Varient, utf32: u32) -> bool {
    index := FT_Get_Char_Index(font_varient.parent_font.font_face, utf32);
    if !index return false;

    font_varient.default_unknown_character = index;
    return true;
}

FT_ROUND :: inline (x: int) -> int {
    if x >= 0 return (x + 0x1f) >> 6;
    return -(((-x) + 0x1f) >> 6);
}

convert_to_utf32 :: inline (s: *u8) -> u32 {
    utf32 := character_utf8_to_utf32(s, IDIOT_CONSTANT); // god I sure hope we don't need more 
    return utf32;
}

font_find_next_atlas_line :: inline (page: *Dynamic_Render_Font_Page, width: u32, height: u32) -> iVector2
{
    bitmap := *page.texture_data.bitmap;
    desired_x := page.bitmap_cursor_x + xx width;
    if desired_x > bitmap.width
    {
        page.bitmap_cursor_x = 0;
        page.bitmap_cursor_y += xx page.parent_varient.max_ascender;
        return .{0, xx page.bitmap_cursor_y};
    }
    else
    {
        return .{xx page.bitmap_cursor_x, xx page.bitmap_cursor_y};
    }
}
copy_glyph_to_page_bitmap :: (page: *Dynamic_Render_Font_Page, glyph: *Font_Glyph_Data)
{
    if page.texture_data.bitmap.data == null
    {
        page.texture_data.bitmap = asset_init_bitmap_arena(*page.parent_varient.parent_font.font_arena,
                                                           2048,
                                                           2048,
                                                          .FORMAT_RGBA);
    }
    assert(page.texture_data.bitmap.data != null);
    
    face := page.parent_varient.parent_font.font_face;
    b    := face.glyph.bitmap;

    glyph.offset_x                = cast,trunc(s16)face.glyph.bitmap_left;
    glyph.offset_y                = cast,trunc(s16)face.glyph.bitmap_top;
    glyph.advance                 = cast,trunc(s16)(face.glyph.advance.x >> 6);

    metrics := *face.glyph.metrics;
    glyph.ascent = cast,trunc(s16)(metrics.horiBearingY >> 6);

    atlas_dest := font_find_next_atlas_line(glyph.owner_page, b.width, b.rows);

    dest_x: s32 = xx atlas_dest.x;
    dest_y: s32 = xx atlas_dest.y;

    glyph.glyph_data.atlas_size.x = xx b.width;
    glyph.glyph_data.atlas_size.y = xx b.rows;

    glyph.glyph_data.atlas_offset.x = dest_x;
    glyph.glyph_data.atlas_offset.y = dest_y;

    bitmap := *glyph.owner_page.texture_data.bitmap;

    rows  := cast(s32)b.rows; 
    width := cast(s32)b.width;
    for j : 0..rows-1 {
        for i : 0..width-1 {
            source_pixel := b.buffer[(rows - 1 - j) * b.pitch + i];

            dest_pixel := bitmap.data + ((dest_y + j) * bitmap.width + (dest_x + i)) * 4;
            dest_pixel[0] = source_pixel;
            dest_pixel[1] = source_pixel;
            dest_pixel[2] = source_pixel;
            dest_pixel[3] = source_pixel;
        }
    }
    glyph.owner_page.bitmap_cursor_x += cast(s16) b.width;
}

asset_get_font_glyph :: (font_varient: *Dynamic_Render_Font_Varient, char: *u8) -> *Font_Glyph_Data
{
    result     : *Font_Glyph_Data;
    found_page : *Dynamic_Render_Font_Page;

    utf32_char := convert_to_utf32(char);
    if utf32_char
    {
        temp := tprint("%", utf32_char);

        page_ptr := font_varient.first_page;
        while page_ptr != null
        {
            result = cast(*Font_Glyph_Data)c_hash_get_value(*page_ptr.glyph_lookup, temp);
            if result
            {
                found_page = page_ptr; 
                break;
            }
            page_ptr = page_ptr.next_page;
        }

        if !result && !found_page
        {
            new_page: *Dynamic_Render_Font_Page = font_varient.first_page;
            while new_page
            {
                if !new_page.page_full
                {
                    found_page = new_page;
                    break;
                }
                new_page = new_page.next_page;
            }

            if !found_page
            {
                new_page = font_varient.first_page;
                while new_page
                {
                    if new_page.next_page == null
                    {
                        new_page.next_page                = c_arena_push_struct(*font_varient.parent_font.font_arena, Dynamic_Render_Font_Page);
                        new_page.next_page.glyph_lookup   = c_hash_table_create(*font_varient.parent_font.font_arena, 1024);
                        new_page.next_page.parent_varient = font_varient;
                        new_page.next_page.next_page      = null;

                        found_page = new_page;
                        break;
                        
                    }
                    new_page = new_page.next_page;
                }
            }

            error := FT_Set_Pixel_Sizes(found_page.parent_varient.parent_font.font_face,
                                        0,
                                        xx found_page.parent_varient.character_height);
            assert(!error);

            glyph_index : u32;
            if utf32_char
            {
                glyph_index = FT_Get_Char_Index(found_page.parent_varient.parent_font.font_face, utf32_char);
                if !glyph_index
                {
                    log_error("UTF32 character '%' cannot be found", utf32_char);
                    glyph_index = found_page.parent_varient.default_unknown_character;
                }

                if glyph_index
                {
                    error = FT_Load_Glyph(found_page.parent_varient.parent_font.font_face, glyph_index, FT_LOAD_RENDER);
                    assert(!error);
                }
            }
            else
            {
                assert(glyph_index >= 0);
                error = FT_Load_Glyph(found_page.parent_varient.parent_font.font_face, glyph_index, FT_LOAD_RENDER);
                assert(!error);
            }

            data := c_arena_push_struct(*found_page.parent_varient.parent_font.font_arena, Font_Glyph_Data);
            data.glyph_key  = glyph_index;
            data.owner_page = found_page;

            copy_glyph_to_page_bitmap(found_page, data);
            data.owner_page.page_dirty = true;

            c_hash_insert_pair(*found_page.glyph_lookup, copy_string(temp), cast(*void)data);
            result = data;
        }
    }
    else
    {
        log("[ERROR]: Character '%s' does not return a valid utf32 character...", char);
    }
    return result;
}

asset_create_font_at_size :: (font: *Dynamic_Render_Font, pixel_size: s32) -> *Dynamic_Render_Font_Varient
{
    result: *Dynamic_Render_Font_Varient;
    assert(font.raw_font_data.data != null);

    error := FT_New_Memory_Face(ft_library,
                                font.raw_font_data.data,
                             xx font.raw_font_data.count,
                                0,
                               *font.font_face);
    if !error
    {
        result                         = c_arena_push_struct(*font.font_arena, Dynamic_Render_Font_Varient);
        result.first_page              = c_arena_push_struct(*font.font_arena, Dynamic_Render_Font_Page);
        result.first_page.next_page      = null;

        result.first_page.glyph_lookup   = c_hash_table_create(*font.font_arena, 1024);
        result.first_page.parent_varient = result;
        result.pixel_size                = pixel_size;

        success := FT_Set_Pixel_Sizes(font.font_face, 0, xx pixel_size);
        assert(!success);

        font_scale_to_pixels := font.font_face.size.metrics.y_scale / (64.0 * 65536.0); 
        result.character_height = pixel_size;
        result.line_spacing     = cast(int)floor(font_scale_to_pixels * font.font_face.height + 0.5);
        result.max_ascender     = cast(int)floor(font_scale_to_pixels * font.font_face.bbox.yMax + 0.5);
        result.max_descender    = cast(int)floor(font_scale_to_pixels * font.font_face.bbox.yMin + 0.5);
        result.parent_font      = font;

        glyph_index := FT_Get_Char_Index(font.font_face, #char "m");
        if glyph_index {
            FT_Load_Glyph(font.font_face, glyph_index, FT_LOAD_DEFAULT);
            result.y_center_offset = xx (0.5 * FT_ROUND(font.font_face.glyph.metrics.horiBearingY) + 0.5);
        }

        glyph_index  = FT_Get_Char_Index(font.font_face, #char "M");
        if glyph_index {
            FT_Load_Glyph(font.font_face, glyph_index, FT_LOAD_DEFAULT);
            result.em_width = FT_ROUND(font.font_face.glyph.metrics.width);
        }

        glyph_index  = FT_Get_Char_Index(font.font_face, #char "T");
        if glyph_index {
            FT_Load_Glyph(font.font_face, glyph_index, FT_LOAD_DEFAULT);
            result.typical_ascender = FT_ROUND(font.font_face.glyph.metrics.horiBearingY);
        }

        glyph_index  = FT_Get_Char_Index(font.font_face, #char "g");
        if glyph_index {
            FT_Load_Glyph(font.font_face, glyph_index, FT_LOAD_DEFAULT);
            result.typical_descender = FT_ROUND(font.font_face.glyph.metrics.horiBearingY - font.font_face.glyph.metrics.height);
        }

        error := FT_Select_Charmap(font.font_face, .UNICODE);
        if error
        {
            log_error("Font does not support UNICODE...\n");
        }

        {
            success             := set_unknown_character(result, 0xfffd);  // replacement_character
            if !success  success = set_unknown_character(result, 0x2022);  // bullet
            if !success  success = set_unknown_character(result, #char "?");
            if !success {
                log_error("unable to set unknown character for font '%'.\n", basename);
            }
        }

        array_add(*font.pixel_sizes, result);
    }
    else
    {
        log("[ERROR]: FT_New_Memory_Face() has failed...\n");
    }

    return result;
}

asset_get_font_at_size_from_hash :: (asset_manager: *Asset_Manager, font_name: string, pixel_size: s32) -> *Dynamic_Render_Font_Varient
{
    result: *Dynamic_Render_Font_Varient;

    font := asset_get_font(asset_manager, font_name);
    if font
    {
        result = asset_get_font_at_size(font, pixel_size);
    }
    else
    {
        log("[ERROR]: Font is invalid...\n");
        assert(false);
    }

    return result;
}

asset_get_font_at_size :: (font: *Dynamic_Render_Font, desired_pixel_size: s32) -> *Dynamic_Render_Font_Varient
{
    result: *Dynamic_Render_Font_Varient;
    for *pixel_size: font.pixel_sizes
    {
        if pixel_size.pixel_size == desired_pixel_size
        {
            result = pixel_size;
            break;
        }
    }

    if !result
    {
        result = asset_create_font_at_size(font, desired_pixel_size);
    }

    return result;
}

asset_get_font :: (asset_manager: *Asset_Manager, hash_name: string) -> *Dynamic_Render_Font
{
    result: *Dynamic_Render_Font;
    
    asset_slot := cast(*Asset_Slot)c_hash_get_value(*asset_manager.render_font_hash, hash_name);
    if asset_slot != null
    {
        font_data := *asset_slot.font_data;
        if font_data.raw_font_data.data == null
        {
            font_data.raw_font_data = read_entire_file(font_data.filepath);
            font_data.font_arena    = c_arena_init(MB(50));
        }

        result = font_data;
    }
    else
    {
        log("[ERROR]: A font with the the name '%' is cannot be found...\n");
    }

    return result;
}

#scope_file
ft_library: FT_Library;
IDIOT_CONSTANT :: 1000; // this is fucking stupid
