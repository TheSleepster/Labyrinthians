Texture_Atlas_Data :: struct
{
    atlas_sprites: *[..]*Static_Sprite2D;
};

Atlas_Builder :: struct
{
    zone_allocator  : *Zone_Allocator;

    atlas_width     :  s32;
    atlas_height    :  s32;

    textures_to_add : [64]*Texture2D;
    texture_counter : s32;

    atlas_texture   :  Texture2D;
    atlas_bitmap    : *Bitmap;

    bitmap_cursor_x : s32;
    bitmap_cursor_y : s32;
    bitmap_tallest_y: s32;
};

ab_init_atlas_builder :: (zone         : *Zone_Allocator,
                          atlas_width  :  s32,
                          atlas_height :  s32,
                          bitmap_format:  Bitmap_Format) -> Atlas_Builder
{
    result: Atlas_Builder;
    result.zone_allocator              = zone;
    result.atlas_texture.bitmap.width  = atlas_width;
    result.atlas_texture.bitmap.height = atlas_height;
    result.atlas_bitmap                = *result.atlas_texture.bitmap;

    return result;
}

ab_add_texture_to_builder_atlas :: (asset_manager : *Asset_Manager,
                                    atlas_builder : *Atlas_Builder,
                                    sprite_data   : *Static_Sprite2D)
{
    assert(atlas_builder.atlas_width  > 0);
    assert(atlas_builder.atlas_height > 0);
    
    sprite_data.atlas_size = .{sprite_data.parent_texture.bitmap.width, sprite_data.parent_texture.bitmap.height};
}
