// NOTE(Sleepster): Capped at 64 bitmaps, if you want to add more than 64 in a single go? Just call the function again. 
Atlas_Builder_Data :: struct
{
    bitmap_ptr    : *Bitmap;
    texture_ptr   : *Texture2D;
    static_sprites: [..]*Static_Sprite2D;
};

Atlas_Builder :: struct
{
    zone_allocator     : *Zone_Allocator;

    textures_to_insert : [64]*Texture2D;
    texture_counter    :  u32;

    atlas_width        :  u32;
    atlas_height       :  u32;

    atlas_bitmap       :  Bitmap;
    atlas_bitmap_format:  Bitmap_Format;

    bitmap_cursor_x    :  u32;
    bitmap_cursor_y    :  u32;
    bitmap_tallest_y   :  u32;

    atlas_builder_data : Atlas_Builder_Data;
};

atlas_builder_init :: (zone: *Zone_Allocator, atlas_width: u32, atlas_height: u32) -> Atlas_Builder
{
    result: Atlas_Builder;
    result.atlas_width    = atlas_width;
    result.atlas_height   = atlas_height;
    result.zone_allocator = zone;

    return result;
}

atlas_builder_add_texture_to_build_list :: inline (atlas_builder: *Atlas_Builder, texture: *Texture2D)
{
    atlas_builder.textures_to_insert[atlas_builder.texture_counter] = texture;
    atlas_builder.texture_counter += 1;
}

// TODO(Sleepster): This is a very bad atlas builder, it's not very efficient, but I don't care!, I'll fix it later 
atlas_builder_build_atlas_bitmap :: (asset_manager          : *Asset_Manager,
                                     atlas_builder          : *Atlas_Builder,
                                     auto_bake_texture_atlas:  bool = true)
{
    if atlas_builder.atlas_bitmap.data == null
    {
        atlas_builder.atlas_bitmap = asset_init_bitmap(atlas_builder.zone_allocator,
                                                    xx atlas_builder.atlas_width,
                                                    xx atlas_builder.atlas_height,
                                                    xx atlas_builder.atlas_bitmap_format); 
    }
    assert(atlas_builder.atlas_bitmap.data != null);

    new_texture_count := atlas_builder.texture_counter;
    for texture_index: 0..atlas_builder.texture_counter - 1
    {
        texture := atlas_builder.textures_to_insert[texture_index];
        if texture.bitmap.format == atlas_builder.atlas_bitmap_format
        {
            sprite_slot := c_arena_push_struct(*asset_manager.hash_data_arena, Asset_Slot);
            sprite_slot.slot_state = .LOADED;

            texture_rect := *sprite_slot.sprite_data;
            texture_rect.parent_texture = texture;
            texture_rect.atlas_size     = .{texture.bitmap.width, texture.bitmap.height};
            if atlas_builder.bitmap_cursor_x + xx texture_rect.atlas_size.x > cast(u32)atlas_builder.atlas_bitmap.width
            {
                atlas_builder.bitmap_cursor_y += (atlas_builder.bitmap_tallest_y + 1);
                atlas_builder.bitmap_cursor_x  = 0;
                atlas_builder.bitmap_tallest_y = 0;
            }

            if atlas_builder.bitmap_cursor_y + cast(u32)texture_rect.atlas_size.y > cast(u32)atlas_builder.atlas_bitmap.height
            {
                log("[ERROR]: The atlas has been filled... returning...\n");
                return;
            }

            texture_rect.atlas_offset = .{cast(s32)atlas_builder.bitmap_cursor_x, cast(s32)atlas_builder.bitmap_cursor_y};
            if texture_rect.atlas_size.y > cast(s32)atlas_builder.bitmap_tallest_y
            {
                atlas_builder.bitmap_tallest_y = cast(u32)texture_rect.atlas_size.y;
            }

            atlas_builder.bitmap_cursor_x += cast(u32)(texture_rect.atlas_size.x + 1);
            for x: 0..texture_rect.atlas_size.x - 1
            {
                for y: 0..texture_rect.atlas_size.y - 1
                {
                    atlas_texture_data_offset := ((texture_rect.atlas_offset.y + y)  * atlas_builder.atlas_bitmap.width +
                                                  (texture_rect.atlas_offset.x + x)) * cast(s32)atlas_builder.atlas_bitmap.channels;

                    sprite_texture_data_offset := (y * texture_rect.atlas_size.x + x) * xx texture_rect.parent_texture.bitmap.format;
                    for channel_index: 0..texture_rect.parent_texture.bitmap.channels - 1
                    {
                        atlas_builder.atlas_bitmap.data[atlas_texture_data_offset + cast(s32)channel_index] =
                            texture_rect.parent_texture.bitmap.data[sprite_texture_data_offset + cast(s32)channel_index];
                    }
                }
            }

            c_hash_insert_pair(*asset_manager.sprite_hash, texture.hash_name, sprite_slot);
            array_add(*atlas_builder.atlas_builder_data.static_sprites, texture_rect);
            atlas_builder.atlas_bitmap.is_dirty = true;

            atlas_builder.textures_to_insert[texture_index] = null;
            new_texture_count -= 1;
        }
        else
        {
            log("[ERROR]: Bitmap has a format of '%', while the atlas has a bitmap format of '%'... Incompatible, skipping...\n");
            assert(false);
        }
    }

    assert(new_texture_count >= 0);
    atlas_builder.texture_counter = new_texture_count;
}

atlas_builder_create_atlas_texture_and_add_to_hash :: inline (asset_manager: *Asset_Manager,
                                                              atlas_builder: *Atlas_Builder,
                                                              hash_name    : string) -> *Texture2D
{
    asset_slot := c_arena_push_struct(*asset_manager.hash_data_arena, Asset_Slot);
    asset_slot.slot_state = .LOADED;

    texture_data := *asset_slot.texture;
    texture_data.* = atlas_builder_create_texture(asset_manager, atlas_builder);

    texture_data.atlas_data = c_arena_push_struct(*asset_manager.hash_data_arena, Atlas_Builder_Data);
    memcpy(*texture_data.atlas_data, *atlas_builder.atlas_builder_data, size_of(Atlas_Builder_Data));
    texture_data.atlas_data.texture_ptr = *asset_slot.texture;

    texture_data.hash_name = hash_name;
    c_hash_insert_pair(*asset_manager.texture_hash, hash_name, asset_slot);

    return *asset_slot.texture;
}

atlas_builder_create_texture :: inline (asset_manager: *Asset_Manager, atlas_builder: *Atlas_Builder) -> Texture2D
{
    result := asset_create_texture_from_bitmap(atlas_builder.atlas_bitmap, false, .NEAREST);
    return result;
}

atlas_builder_reset :: inline (atlas_builder: *Atlas_Builder)
{
    zone_allocator := atlas_builder.zone_allocator;
    array_free(atlas_builder.atlas_builder_data.static_sprites);

    atlas_builder.* = .{};
    atlas_builder.zone_allocator = zone_allocator;
}
