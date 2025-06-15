Texture_Atlas_Data :: struct
{
    sprite_hash     :   C_Hash_Table;
    sprite_key_count:   u32;
    sprite_hash_keys: []string;
};

Atlas_Builder :: struct
{
    zone_allocator     : *Zone_Allocator;
    store_keys         :  bool;

    atlas_width        :  s32;
    atlas_height       :  s32;

    textures_to_add    : [64]*Texture2D;
    texture_counter    :  s32;

    atlas_texture      :  Texture2D;
    atlas_bitmap       : *Bitmap;
    atlas_bitmap_format:  Bitmap_Format;

    bitmap_cursor_x    :  s32;
    bitmap_cursor_y    :  s32;
    bitmap_tallest_y   :  s32;
};

ab_init_atlas_builder :: (zone         : *Zone_Allocator,
                          atlas_width  :  s32,
                          atlas_height :  s32,
                          bitmap_format:  Bitmap_Format,
                          store_keys   :  bool) -> Atlas_Builder
{
    result: Atlas_Builder;
    result.zone_allocator              =  zone;
    result.atlas_width                 =  atlas_width;
    result.atlas_height                =  atlas_height;
    result.atlas_texture.bitmap.width  =  atlas_width;
    result.atlas_texture.bitmap.height =  atlas_height;
    result.atlas_bitmap                = *result.atlas_texture.bitmap;
    result.store_keys                  =  store_keys;

    return result;
}

ab_add_bitmap_to_atlas :: (atlas_builder: *Atlas_Builder,
                           sprite_data  : *Static_Sprite2D)
{
    for x: 0..sprite_data.atlas_size.x - 1
    {
        for y: 0..sprite_data.atlas_size.y - 1
        {
            atlas_texture_data_offset := ((sprite_data.atlas_offset.y + y)  * xx atlas_builder.atlas_bitmap.width +
                                          (sprite_data.atlas_offset.x + x)) * xx atlas_builder.atlas_bitmap.channels;

            sprite_texture_data_offset := (y * sprite_data.atlas_size.x + x) * xx sprite_data.parent_texture.bitmap.channels;
            for channel_index: 0..sprite_data.parent_texture.bitmap.channels - 1
            {
                atlas_builder.atlas_bitmap.data[xx atlas_texture_data_offset + channel_index] =
                    sprite_data.parent_texture.bitmap.data[xx sprite_texture_data_offset + channel_index];
            }
        }
    }
}

ab_add_texture_to_builder_atlas :: (asset_manager : *Asset_Manager,
                                    atlas_builder : *Atlas_Builder,
                                    parent_texture: *Texture2D) -> *Static_Sprite2D
{
    assert(atlas_builder.atlas_width  > 0);
    assert(atlas_builder.atlas_height > 0);
    assert(atlas_builder.atlas_bitmap != null);

    sprite_data := cast(*Static_Sprite2D)za_alloc(atlas_builder.zone_allocator, size_of(Static_Sprite2D), .STATIC);

    if atlas_builder.atlas_texture.atlas_data == null 
    {
        atlas_builder.atlas_texture.atlas_data                  = za_alloc(atlas_builder.zone_allocator, size_of(Texture_Atlas_Data), .STATIC);
        atlas_builder.atlas_texture.atlas_data.sprite_hash      = c_hash_table_create_za(atlas_builder.zone_allocator, 512);
        atlas_builder.atlas_texture.atlas_data.sprite_hash_keys = za_alloc_array(atlas_builder.zone_allocator,
                                                                                 string,
                                                                                 512,
                                                                                .STATIC);
    }
    assert(atlas_builder.atlas_texture.atlas_data != null);
    atlas_data := atlas_builder.atlas_texture.atlas_data;

    sprite_data.parent_texture = parent_texture;
    if atlas_builder.store_keys
    {
        atlas_data.sprite_hash_keys[atlas_data.sprite_key_count] = parent_texture.hash_name;
        atlas_data.sprite_key_count += 1;
    }

    c_hash_insert_pair(*atlas_data.sprite_hash, parent_texture.hash_name, sprite_data);
    if sprite_data.parent_texture.bitmap.data == null
    {
        assert(sprite_data.parent_texture.hash_name.data != null);
        asset_load_texture_from_hash(asset_manager, sprite_data.parent_texture.hash_name); 
    }

    if atlas_builder.atlas_texture.bitmap.data == null
    {
        atlas_builder.atlas_texture.bitmap = asset_init_bitmap(atlas_builder.zone_allocator,
                                                              atlas_builder.atlas_width,
                                                              atlas_builder.atlas_height,
                                                             .FORMAT_RGBA);
    }
    assert(atlas_builder.atlas_texture.bitmap.data != null);
    atlas_builder.atlas_bitmap = *atlas_builder.atlas_texture.bitmap;
    
    sprite_data.atlas_size = .{sprite_data.parent_texture.bitmap.width, sprite_data.parent_texture.bitmap.height};
    assert(sprite_data.atlas_size.x < atlas_builder.atlas_bitmap.width);
    assert(sprite_data.atlas_size.y < atlas_builder.atlas_bitmap.height);
    if sprite_data.atlas_size.y > atlas_builder.bitmap_tallest_y
    {
        atlas_builder.bitmap_tallest_y = sprite_data.atlas_size.y;
    }
    
    if atlas_builder.bitmap_cursor_x + sprite_data.atlas_size.x > atlas_builder.atlas_width
    {
        atlas_builder.bitmap_cursor_y += atlas_builder.bitmap_tallest_y;
        atlas_builder.bitmap_cursor_x  = 0;
    }

    if atlas_builder.bitmap_cursor_y + sprite_data.atlas_size.y > atlas_builder.atlas_height
    {
        log("[ERROR]: Atlas has been filled to capacity... returning...\n");
        return sprite_data;
    }

    sprite_data.atlas_offset = .{atlas_builder.bitmap_cursor_x, atlas_builder.bitmap_cursor_y};
    atlas_builder.bitmap_cursor_x += sprite_data.atlas_size.x + 1;

    assert(sprite_data.parent_texture.bitmap.data != null);
    ab_add_bitmap_to_atlas(atlas_builder, sprite_data);
    parent_texture.is_in_atlas = true;
    
    if atlas_builder.atlas_texture.texID == 0
    {
        assert(atlas_builder.atlas_bitmap != null);
        assert(atlas_builder.atlas_texture.bitmap.data != null);
        r_upload_texture_to_gpu(*atlas_builder.atlas_texture);

        if atlas_builder.store_keys && atlas_data.sprite_key_count > 0
        {
            for key_index: 0..atlas_data.sprite_key_count - 1
            {
                sprite_key := atlas_data.sprite_hash_keys[key_index];
                sprite := cast(*Static_Sprite2D)c_hash_get_value(*atlas_data.sprite_hash, sprite_key);
                if sprite
                {
                    sprite.atlas_texture = *atlas_builder.atlas_texture;
                }
                else
                {
                    log("[ERROR]: Sprite with the name '%', is not a valid entry to the hash...\n", sprite_key);
                }
            }
        }
    }
    else
    {
        sprite_data.atlas_texture = *atlas_builder.atlas_texture;
        atlas_builder.atlas_bitmap.is_dirty = true;
        r_update_gpu_texture_from_bitmap(*atlas_builder.atlas_texture);
    }
    return sprite_data;
}

ab_reset_builder :: (asset_manager       : *Asset_Manager,
                     atlas_builder       : *Atlas_Builder,
                     push_to_texture_hash: bool   = false,
                     hash_name           : string = "") -> bool
{
    if push_to_texture_hash
    {
        assert(hash_name != "");

        asset_slot := cast(*Asset_Slot)c_hash_get_value(*asset_manager.texture_hash, hash_name);
        if !asset_slot
        {
            new_slot := c_arena_push_struct(*asset_manager.hash_data_arena, Asset_Slot);
            new_slot.texture_data = atlas_builder.atlas_texture;

            c_hash_insert_pair(*asset_manager.texture_hash, hash_name, new_slot);
        }
        else
        {
            log("[ERROR]: A hash value by the name of '%' already exists in the texture hash, try again with a different name...\n");
            return false;
        }
    }
    atlas_builder.* = (Atlas_Builder).{};
    atlas_builder.zone_allocator = asset_manager.asset_allocator;

    return true;
}
