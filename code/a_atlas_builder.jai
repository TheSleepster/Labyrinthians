Texture_Atlas_Data :: struct
{
    atlas_sprites: [..]*Static_Sprite2D;
};

Atlas_Builder :: struct
{
    zone_allocator     : *Zone_Allocator;

    atlas_width        :  s32;
    atlas_height       :  s32;

    textures_to_add    : [64]*Texture2D;
    texture_counter    : s32;

    atlas_texture      :  Texture2D;
    atlas_bitmap       : *Bitmap;
    atlas_bitmap_format: Bitmap_Format;

    bitmap_cursor_x    : s32;
    bitmap_cursor_y    : s32;
    bitmap_tallest_y   : s32;
};

ab_init_atlas_builder :: (zone         : *Zone_Allocator,
                          atlas_width  :  s32,
                          atlas_height :  s32,
                          bitmap_format:  Bitmap_Format) -> Atlas_Builder
{
    result: Atlas_Builder;
    result.zone_allocator              =  zone;
    result.atlas_width                 =  atlas_width;
    result.atlas_height                =  atlas_height;
    result.atlas_texture.bitmap.width  =  atlas_width;
    result.atlas_texture.bitmap.height =  atlas_height;
    result.atlas_bitmap                = *result.atlas_texture.bitmap;

    return result;
}

ab_add_bitmap_to_atlas :: (atlas_builder: *Atlas_Builder,
                           sprite_data  : *Static_Sprite2D)
{
    for x: 0..sprite_data.atlas_size.x - 1
    {
        for y: 0..sprite_data.atlas_size.y - 1
        {
            atlas_texture_data_offset := ((sprite_data.atlas_offset.y + y)  * atlas_builder.atlas_bitmap.width +
                                          (sprite_data.atlas_offset.x + x)) * cast(s32)atlas_builder.atlas_bitmap.channels;

            sprite_texture_data_offset := (y * sprite_data.atlas_size.x + x) * xx sprite_data.parent_texture.bitmap.format;
            for channel_index: 0..sprite_data.parent_texture.bitmap.channels - 1
            {
                atlas_builder.atlas_bitmap.data[atlas_texture_data_offset + cast(s32)channel_index] =
                    sprite_data.parent_texture.bitmap.data[sprite_texture_data_offset + cast(s32)channel_index];
            }
        }
    }
}

ab_add_texture_to_builder_atlas :: (asset_manager : *Asset_Manager,
                                    atlas_builder : *Atlas_Builder,
                                    parent_texture: *Texture2D,
                                    sprite_data   : *Static_Sprite2D)
{
    assert(atlas_builder.atlas_width  > 0);
    assert(atlas_builder.atlas_height > 0);
    assert(atlas_builder.atlas_bitmap != null);

    sprite_data = za_alloc(atlas_builder.zone_allocator, size_of(Static_Sprite2D), .STATIC);
    atlas_builder.atlas_texture.atlas_data = za_alloc(atlas_builder.zone_allocator, size_of(Texture_Atlas_Data), .STATIC);
    array_add(*atlas_builder.atlas_texture.atlas_data.atlas_sprites, sprite_data);
    sprite_data.parent_texture = parent_texture;

    if atlas_builder.atlas_texture.bitmap.data == null
    {
        atlas_builder.atlas_bitmap.* = asset_init_bitmap(atlas_builder.zone_allocator,
                                                         atlas_builder.atlas_width,
                                                         atlas_builder.atlas_height,
                                                      xx atlas_builder.atlas_bitmap.format);
    }
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
        return;
    }

    sprite_data.atlas_offset = .{atlas_builder.bitmap_cursor_x, atlas_builder.bitmap_cursor_y};
    atlas_builder.bitmap_cursor_x += sprite_data.atlas_size.x + 1;

    assert(sprite_data.parent_texture.bitmap.data != null);
    ab_add_bitmap_to_atlas(atlas_builder, sprite_data);
    if atlas_builder.atlas_texture.texID == 0
    {
        r_upload_texture_to_gpu(*atlas_builder.atlas_texture);
    }
    else
    {
        atlas_builder.atlas_bitmap.is_dirty = true;
        r_update_gpu_texture_from_bitmap(*atlas_builder.atlas_texture);
    }
}
