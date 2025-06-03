Texture_Atlas_Data :: struct
{
    atlas_sprites: [..]*Static_Sprite2D;
};

Atlas_Builder :: struct
{
    zone_allocator  : *Zone_Allocator;

    atlas_width     :  s32;
    atlas_height    :  s32;

    atlas_texture   :  Texture2D;
    atlas_bitmap    : *Bitmap;

    bitmap_cursor_x : s32;
    bitmap_cursor_y : s32;
    bitmap_tallest_y: s32;
};

ab_add_texture_to_builder_atlas :: (asset_manager : *Asset_Manager,
                                    atlas_builder : *Atlas_Builder,
                                    sprite_data   : *Static_Sprite2D)
{
}
