// NOTE(Sleepster): Rotation is stored as degrees, used as radians 
Render_Primitive_Data :: struct
{
    world_position          : Vector2;
    render_size             : Vector2;
    center_pos              : Vector2;
    
    render_color            : Vector4;
    rotation                : float32;
    is_transparent          : s32;

    // NOTE(Sleepster): These are unique to the rendergroup 
    quad_render_matrix_id   : u32;
    required_shader_id      : u32;
    render_layer            : u32;
    required_texture_id     : u32;
    render_texture_idx      : u32;

    render_options          : Rendering_Options;

    required_shader         : *GPU_Shader;
    required_render_material: *Render_Material;
};

Render_Line :: struct
{
    using primitive_data: Render_Primitive_Data;
    union
    {
        elements: [2]Vertex;
        struct
        {
            start: Vertex;
            end  : Vertex;
        };
    };
};

Render_Triangle :: struct
{
    using primitive_data: Render_Primitive_Data;
    union
    {
        elements: [3]Vertex;
        struct
        {
            bottom_left : Vertex;
            top_middle  : Vertex;
            bottom_right: Vertex;
        };
    };
};

Render_Quad :: struct
{
    using primitive_data: Render_Primitive_Data;
    union
    {
        elements: [4]Vertex;
        struct
        {
            bottom_left : Vertex;
            top_left    : Vertex;
            top_right   : Vertex;
            bottom_right: Vertex;
        };
    };
};

Occluder2D :: struct
{
    using quad_data: Render_Quad;

    light_atlas_cell_index   : u32;
    light_atlas_channel_index: u32;
    influenced_light_index   : s32;
};

r_create_draw_quad :: (render_state  : *Render_State,
                       quad_buffer   : *Render_Group_Quad_Buffer,
                       position      :  Vector2,
                       render_size   :  Vector2,
                       draw_color    :  Vector4,
                       texture_id    :  u32,
                       rotation      :  float32,
                       render_options:  u32,
                       atlas_offset  :  Vector2,
                       sprite_size   :  Vector2) -> bool, Render_Quad
{
    culled: bool;
    
    quad: Render_Quad;
    quad.world_position = position;
    quad.render_size    = render_size;
    quad.render_color   = draw_color;
    quad.rotation       = rotation;
    quad.render_options = xx render_options;

    quad.center_pos = quad.world_position + (quad.render_size * 0.5);

    top    := position.y;
    bottom := position.y + render_size.y;
    left   := position.x;
    right  := position.x + render_size.x;

    top_left     := (Vector2).{left,   top};
    top_right    := (Vector2).{right,  top};
    bottom_left  := (Vector2).{left,   bottom};
    bottom_right := (Vector2).{right, bottom};

    // NOTE(Sleepster): early culling 
    world_to_clip := multiply(render_state.draw_frame.active_projection_matrix, render_state.draw_frame.active_view_matrix);
    quad_min      := mat4_transform(world_to_clip, v2_expand(top_left, 0, 1));
    quad_max      := mat4_transform(world_to_clip, v2_expand(bottom_right, 0, 1));

    if quad_max.x < -1 || quad_min.x > 1 ||
       quad_max.y < -1 || quad_min.y > 1
    {
        culled = true;
        return culled, (Render_Quad).{};
    }
    
    // NOTE(Sleepster): transparency 
    if quad.render_color.w < 1.0
    {
        quad.is_transparent = 1;
        quad_buffer.t_quad_count += 1;
    }

    // NOTE(Sleepster): draw_frame matrix stuff 
    if (render_state.draw_frame.active_view_matrix       != render_state.draw_frame.previous_view_matrix) ||
       (render_state.draw_frame.active_projection_matrix != render_state.draw_frame.previous_projection_matrix)
    {
        count := render_state.draw_frame.current_render_matrix_id;

        render_state.draw_frame.used_projection_matrices[count] = render_state.draw_frame.active_projection_matrix;
        render_state.draw_frame.used_view_matrices[count]       = render_state.draw_frame.active_view_matrix;

        render_state.draw_frame.previous_view_matrix            = render_state.draw_frame.active_view_matrix;
        render_state.draw_frame.previous_projection_matrix      = render_state.draw_frame.active_projection_matrix;

        render_state.draw_frame.current_render_matrix_id += 1;
    }

    quad.quad_render_matrix_id    =  render_state.draw_frame.current_render_matrix_id - 1;
    quad.required_shader          =  render_state.draw_frame.active_shader;
    quad.required_render_material =  render_state.draw_frame.active_render_material;
    quad.required_shader_id       =  quad.required_shader.program_id;

    quad.required_texture_id     = texture_id;
    quad.render_layer            = render_state.draw_frame.current_render_layer;

    quad.top_left.vVSNormals     = .{1, 0, 1};
    quad.bottom_left.vVSNormals  = .{0, 1, 1};
    quad.bottom_right.vVSNormals = .{1, 1, 1};
    quad.top_right.vVSNormals    = .{0, 0, 1};

    if texture_id != U32_MAX
    {
        if !(render_options & xx Rendering_Options.RO_TEXEL_FETCHED)
        {
            quad.top_left.vTexelData     = .{0, 0};
            quad.top_right.vTexelData    = .{1, 0};
            quad.bottom_left.vTexelData  = .{0, 1};
            quad.bottom_right.vTexelData = .{1, 1};
        }
        else
        {
            quad.top_left.vTexelData     = .{atlas_offset.x,                 atlas_offset.y};
            quad.bottom_left.vTexelData  = .{atlas_offset.x,                 atlas_offset.y + sprite_size.y};
            quad.bottom_right.vTexelData = .{atlas_offset.x + sprite_size.x, atlas_offset.y + sprite_size.y};
            quad.top_right.vTexelData    = .{atlas_offset.x + sprite_size.x, atlas_offset.y};
        }

        for *element: quad.elements
        {
            element.vTextureIndex  = texture_id;
        }
    }

    // TODO(Sleepster): Maybe move the rotation math over to the GPU? 
    if rotation != 0
    {
        C_x := position.x + render_size.x / 2;
        C_y := position.y + render_size.y / 2;

        cos_theta := cos(rotation);
        sin_theta := sin(rotation);

        // top_left
        dx := top_left.x - C_x;
        dy := top_left.y - C_y;
        rotated_top_left_x := C_x + dx * cos_theta + dy * sin_theta;
        rotated_top_left_y := C_y - dx * sin_theta + dy * cos_theta;
        rotated_top_left   := (Vector2).{rotated_top_left_x, rotated_top_left_y};

        // top_right
        dx = top_right.x - C_x;
        dy = top_right.y - C_y;
        rotated_top_right_x := C_x + dx * cos_theta + dy * sin_theta;
        rotated_top_right_y := C_y - dx * sin_theta + dy * cos_theta;
        rotated_top_right   := (Vector2).{rotated_top_right_x, rotated_top_right_y};

        // bottom_left
        dx = bottom_left.x - C_x;
        dy = bottom_left.y - C_y;
        rotated_bottom_left_x := C_x + dx * cos_theta + dy * sin_theta;
        rotated_bottom_left_y := C_y - dx * sin_theta + dy * cos_theta;
        rotated_bottom_left   := (Vector2).{rotated_bottom_left_x, rotated_bottom_left_y};

        // bottom_right
        dx = bottom_right.x - C_x;
        dy = bottom_right.y - C_y;
        rotated_bottom_right_x := C_x + dx * cos_theta + dy * sin_theta;
        rotated_bottom_right_y := C_y - dx * sin_theta + dy * cos_theta;
        rotated_bottom_right   := (Vector2).{rotated_bottom_right_x, rotated_bottom_right_y};

        quad.top_left.vPosition     = make_vector4(rotated_top_left, 0, 1);
        quad.bottom_right.vPosition = make_vector4(rotated_bottom_right, 0, 1);
        quad.top_right.vPosition    = make_vector4(rotated_top_right, 0, 1);
        quad.bottom_left.vPosition  = make_vector4(rotated_bottom_left, 0, 1);
    }
    else
    {
        quad.top_left.vPosition     = make_vector4(top_left, 0, 1);
        quad.bottom_left.vPosition  = make_vector4(bottom_left, 0, 1);
        quad.top_right.vPosition    = make_vector4(top_right, 0, 1);
        quad.bottom_right.vPosition = make_vector4(bottom_right, 0, 1);
    }

    for *element: quad.elements
    {
        element.vColor         = draw_color;
        element.vRenderOptions = render_options;
        element.vRenderLayer   = render_state.draw_frame.current_render_layer;
    }

    if ((quad.render_options & .RO_OCCLUDER) != 0) && !culled
    {
        render_state.occluder2D_quad_buffer[render_state.draw_frame.occluder2D_count].quad_data = quad;
        render_state.draw_frame.occluder2D_count += 1;
    }

    return culled, quad;
}

// NOTE(Sleepster): Pass Radians to these functions
r_draw_quad :: (render_state  : *Render_State,
                position      :  Vector2,
                render_size   :  Vector2,
                draw_color    :  Vector4,
                texture_id    :  u32               =  U32_MAX,
                render_options:  Rendering_Options = .RO_NONE, 
                rotation      :  float32           =  0.0)
{
    assert(!(render_options & .RO_TEXEL_FETCHED));
    current_buffer      := r_get_render_group_quad_buffer(render_state);
    culled, render_quad := r_create_draw_quad(render_state,
                                              current_buffer,
                                              position,
                                              render_size,
                                              draw_color,
                                              texture_id,
                                              rotation,
                                           xx render_options,
                                              (Vector2).{},
                                              (Vector2).{});
    if !culled
    {
        current_buffer.quad_buffer[current_buffer.quad_count] = render_quad;
        current_buffer.quad_count += 1;
    }
}

r_draw_sprite :: (render_state   : *Render_State,
                  position       : Vector2,
                  render_size    : Vector2,
                  draw_color     : Vector4,
                  atlas_sprite   : *Static_Sprite2D,
                  rotation       : float32           = 0.0,
                  render_options : Rendering_Options = .RO_NONE)
{
    current_buffer := r_get_render_group_quad_buffer(render_state);
    render_options |= .RO_TEXEL_FETCHED;
    culled, render_quad := r_create_draw_quad(render_state,
                                              current_buffer,
                                              position,
                                              render_size,
                                              draw_color,
                                              atlas_sprite.atlas_texture.texID,
                                              rotation,
                                           xx render_options,
                                              v2_cast(atlas_sprite.atlas_offset),
                                              v2_cast(atlas_sprite.atlas_size));
    if !culled
    {
        current_buffer.quad_buffer[current_buffer.quad_count] = render_quad;
        current_buffer.quad_count += 1;
    }
}

// NOTE(Sleepster): spot_angle is in radians 
r_create_point_light :: (render_state: *Render_State,
                         position    :  Vector2,
                         light_color :  Vector4,
                         direction   :  Vector2,
                         spot_angle  :  float32,
                         radius      :  float32,
                         strength    :  float32 = 1.0) -> *Point_Light
{
    assert(render_state.draw_frame.light_count + 1 < MAX_LIGHTS);
    assert(render_state.shader_point_light_buffer.data != null);
    assert(render_state.engine_point_light_buffer.data != null);
    
    light_data   := *render_state.shader_point_light_buffer[render_state.draw_frame.light_count];
    engine_light := *render_state.engine_point_light_buffer[render_state.draw_frame.light_count];

    engine_light.light_data = light_data;
    light_data.light_color  = light_color;

    world_to_clip := multiply(render_state.draw_frame.active_view_matrix, render_state.draw_frame.active_projection_matrix);
    NDC_position  := mat4_transform(world_to_clip, v2_expand(position, 0, 1));
    if NDC_position.x < -1 || NDC_position.x > 1 ||
       NDC_position.y < -1 || NDC_position.y > 1
    {
        log("[INFO]: Light Culled...\n");
        return null;
    }
    light_data_pos := mat4_transform(render_state.draw_frame.active_view_matrix, v2_expand(position, 0, 1));

    engine_light.ws_position               = position;
    engine_light.light_atlas_channel_index = render_state.draw_frame.light_atlas_channel_index;
    engine_light.light_atlas_cell_index    = render_state.draw_frame.light_atlas_cell_index;

    render_state.draw_frame.light_atlas_channel_index += 1;
    if render_state.draw_frame.light_atlas_channel_index > 3
    {
        render_state.draw_frame.light_atlas_channel_index = 0;
        render_state.draw_frame.light_atlas_cell_index   += 1;
    }

    light_data.vs_position   = light_data_pos.xy;
    light_data.cs_position   = NDC_position.xy;

    light_data.spot_angle    = spot_angle;
    light_data.radius        = radius;
    light_data.direction     = direction;
    light_data.strength      = strength;

    render_state.draw_frame.light_count += 1;

    return engine_light;
}

r_prepare_string :: (varient: *Dynamic_Render_Font_Varient, text: string) -> s32 
{
    result: s32;
    
    temp := text.data;
    glyph: *Font_Glyph_Data;
    while temp < text.data + text.count
    {
        char: string;
        char.data = temp; 
        char.count = 1;
        
        glyph      = asset_get_font_glyph(varient, temp);
        result    += xx (glyph.glyph_data.atlas_size.x + xx glyph.advance);
        temp       = unicode_next_character(temp);
    }
    
    if glyph.owner_page.page_dirty
    {
        if glyph.owner_page.texture_data.texID != 0
        {
            r_update_gpu_texture_from_bitmap(*glyph.owner_page.texture_data);
        }
        else
        {
            r_upload_texture_to_gpu(*glyph.owner_page.texture_data, .LINEAR, true);
        }
        glyph.owner_page.page_dirty = false;
    }
    return result;
}

r_draw_text :: (render_state: *Render_State,
                dynamic_font : *Dynamic_Render_Font,
                text         :  string,
                center_pos   :  Vector2,
                font_scale   :  s32,
                color        :  Vector4)
{
    draw_frame := *render_state.draw_frame;
    font_page  := asset_get_font_at_size(dynamic_font, font_scale);
    if font_page != null
    {
        total_width  : s32 = r_prepare_string(font_page, text);
        starting_pos := (Vector2).{center_pos.x - (total_width * 0.5), center_pos.y};
        render_pos   := starting_pos;
        
        temp := text.data;
        while temp < text.data + text.count
        {
            char: string;
            char.data = temp; 
            char.count = 1;

            glyph := asset_get_font_glyph(font_page, temp);
            if temp == " "
            {
                render_pos.x += glyph.advance;
                continue;
            }

            glyph.glyph_data.atlas_texture = *glyph.owner_page.texture_data;
            r_draw_sprite(render_state,
                         (Vector2).{floor(render_pos.x + glyph.offset_x), floor(render_pos.y + (glyph.ascent - xx glyph.glyph_data.atlas_size.y))},
                         .{xx glyph.glyph_data.atlas_size.x, xx glyph.glyph_data.atlas_size.y},
                          color,
                         *glyph.glyph_data,
                          0.0,
                         .RO_UNLIT);
            render_pos.x += glyph.advance;
            temp          = unicode_next_character(temp);
        }
    }
    else
    {
        log_error("Failed to get the font page data back from the asset system...\n");
    }
}

r_push_render_layer :: inline (render_state: *Render_State, layer: u32)
{
    render_state.draw_frame.current_render_layer = layer;
}

r_set_render_material :: inline (render_state: *Render_State, material: *Render_Material)
{
    render_state.draw_frame.active_render_material = material;
}

r_set_render_view_matrix :: inline (render_state: *Render_State, matrix: Matrix4)
{
    render_state.draw_frame.active_view_matrix = matrix;
}

r_set_render_projection_matrix :: inline (render_state: *Render_State, matrix: Matrix4)
{
    render_state.draw_frame.active_projection_matrix = matrix;
}

r_set_render_matrices :: inline (render_state: *Render_State, view_matrix: Matrix4, projection_matrix: Matrix4)
{
    render_state.draw_frame.active_view_matrix       = view_matrix;
    render_state.draw_frame.active_projection_matrix = projection_matrix;
}

Light_Occluder_Pair :: struct
{
    light_index   : u32;
    occluder_index: u32;
};

r_handle_lighting_data :: (render_state: *Render_State)
{
/*
    What do we want this function to do?
LIGHTING:
       - Compute the correct UVs into the light atlas for all the lights in the current scene
           - Convert a light_atlas_cell_index -> UV coords
       - Assign a vector4 light mask for the channel the light occupies
           - Channel index 0 = .{1, 0, 0, 0}. Channel index 1 = .{0, 1, 0, 0}...
       - Create clip space geometry to store the lighting information in the atlas
           - Create a quad that is made in world space coordinates, bring them to clip space
       - Add this quad to the light quads vertex buffer 
SHADOWS: 
       - For each light, loop over each occluder to figure out if it is within the influence of the light
            - If the occluder IS within range, set it's cell_index and it's channel_index to that of the light's
            - If the occluder ISN'T then skip it
       - For each occluder generate a shadow quad and bring it's transformation space to that of clip space. 
       - Add the quad to the occluder shadow quads vertex buffer.
DRAWING:
       - Render the light mask (occluder) geometry into the light map,
         using the cell_index (which converts to UV coords in the
         bigger lightmap) and color_mask to render it correctly the
         glColorMask() is set to to only write alpha.

       - Render all lights using their lightmap geometry into the
         light map, again using the cell_index and color mask to
         ensure proper writing.
*/
    draw_frame := *render_state.draw_frame;
    render_state.draw_frame.light_atlas_channel_index = 0;

    light_occluder_pairs := c_arena_push_array(*render_state.draw_frame_arena,
                                                Light_Occluder_Pair,
                                                draw_frame.occluder2D_count * draw_frame.light_count);
    light_occluder_pair_count: u32;

    // NOTE(Sleepster): Find out which occluders in the scene effect which lights 
    for light_index: 0..render_state.draw_frame.light_count - 1
    {
        working_light := *render_state.engine_point_light_buffer[light_index];
        working_light.light_buffer_index = light_index;

        draw_frame.light_atlas_cell_index += 1;
        draw_frame.light_atlas_channel_index = (draw_frame.light_atlas_channel_index + 1) % 3;

        // 1.) We are only iterating over the scene's occluder
        // count. This is bad because if we have an occluder that
        // interferes with 2 lights we lose the ability to express that

        // 2.) Currently, because of the previous point if a light is
        // labelled by one light as the owner of the occluder, then the
        // next light will override this information, making it
        // incorrect.

        old_count: u32 = draw_frame.occluder2D_count;
        for occluder_index: 0..old_count - 1
        {
            occluder := *render_state.occluder2D_quad_buffer[occluder_index];
            if is_quad_within_light_radius(working_light, *occluder.quad_data)
            {
                light_occluder_pairs[light_occluder_pair_count] = .{light_index, occluder_index};
                light_occluder_pair_count += 1;
            }
        }
    }

    // NOTE(Sleepster): Process that infromation, generating quads for
    // each light. These quads store information about what cell in the
    // big atlas this light belongs too and what channel.
    for light_index: 0..render_state.draw_frame.light_count - 1
    {
        working_light := *render_state.engine_point_light_buffer[light_index];

        light_mask: [4]float32;
        light_mask.data[working_light.light_atlas_channel_index] = 1.0;

        // NOTE(Sleepster): Compute light atlas data
        cell_x: u32 = working_light.light_atlas_cell_index % (LIGHTMAP_SIZE / MAX_LIGHT_RADIUS);
        cell_y: u32 = working_light.light_atlas_cell_index / (LIGHTMAP_SIZE / MAX_LIGHT_RADIUS);

        cell_U: float32 = (cast(float32)cell_x * cast(float32)MAX_LIGHT_RADIUS) / LIGHTMAP_SIZE;
        cell_V: float32 = (cast(float32)cell_y * cast(float32)MAX_LIGHT_RADIUS) / LIGHTMAP_SIZE;

        light_cell_scale: float32 = (cast(float32)MAX_LIGHT_RADIUS / cast(float32)LIGHTMAP_SIZE);

        working_light.light_data.atlas_uvs  = .{cell_U, cell_V};
        working_light.light_data.light_mask = .{light_mask[0], light_mask[1], light_mask[2], light_mask[3]};

        // NOTE(Sleepster): build the vertices 
        {
            bottom_left_vertex  := *render_state.lightmap_vertex_buffer[render_state.draw_frame.lightmap_vertex_count + 0];
            top_left_vertex     := *render_state.lightmap_vertex_buffer[render_state.draw_frame.lightmap_vertex_count + 1];
            top_right_vertex    := *render_state.lightmap_vertex_buffer[render_state.draw_frame.lightmap_vertex_count + 2];
            bottom_right_vertex := *render_state.lightmap_vertex_buffer[render_state.draw_frame.lightmap_vertex_count + 3];

            start_x := ((cast(float32)-LIGHTMAP_SIZE) * 0.5) + (MAX_LIGHT_RADIUS * cell_x);
            start_y := ((cast(float32)-LIGHTMAP_SIZE) * 0.5) + (MAX_LIGHT_RADIUS * cell_y);
            // NOTE(Sleepster): World Space Position Data 
            {
                end_x   := (start_x + MAX_LIGHT_RADIUS);
                end_y   := (start_y + MAX_LIGHT_RADIUS);
                
                top_left_vertex.vPosition     = .{start_x,  start_y, 0, 1};
                top_right_vertex.vPosition    = .{end_x,    start_y, 0, 1,};
                bottom_left_vertex.vPosition  = .{start_x,  end_y, 0, 1,};
                bottom_right_vertex.vPosition = .{end_x,    end_y, 0, 1,};
            }

            // NOTE(Sleepster): Lightmap atlas UVs
            {
                top_uv    := cell_V;
                left_uv   := cell_U;
                right_uv  := cell_U + light_cell_scale;
                bottom_uv := cell_V + light_cell_scale;

                top_left_vertex.vTexelData     = .{left_uv,  top_uv};
                top_right_vertex.vTexelData    = .{right_uv, top_uv};
                bottom_left_vertex.vTexelData  = .{left_uv,  bottom_uv};
                bottom_right_vertex.vTexelData = .{right_uv, bottom_uv};
            }

            // NOTE(Sleepster): Fragment Positions relative to light radius 
            {
                top_uv    := cell_V;
                left_uv   := cell_U;
                right_uv  := cell_U + light_cell_scale;
                bottom_uv := cell_V + light_cell_scale;

                top_left_vertex.vVSNormals     = .{left_uv,  top_uv,    0.0};
                top_right_vertex.vVSNormals    = .{right_uv, top_uv,    0.0};
                bottom_left_vertex.vVSNormals  = .{left_uv,  bottom_uv, 0.0};
                bottom_right_vertex.vVSNormals = .{right_uv, bottom_uv, 0.0};
            }

            // NOTE(Sleepster): Light Mask 
            top_left_vertex.vColor     = .{light_mask[0], light_mask[1], light_mask[2], light_mask[3]};
            top_right_vertex.vColor    = .{light_mask[0], light_mask[1], light_mask[2], light_mask[3]};
            bottom_left_vertex.vColor  = .{light_mask[0], light_mask[1], light_mask[2], light_mask[3]};
            bottom_right_vertex.vColor = .{light_mask[0], light_mask[1], light_mask[2], light_mask[3]};

            top_left_vertex.vTextureIndex     = working_light.light_buffer_index;
            top_right_vertex.vTextureIndex    = working_light.light_buffer_index;
            bottom_left_vertex.vTextureIndex  = working_light.light_buffer_index;
            bottom_right_vertex.vTextureIndex = working_light.light_buffer_index;
        }

        render_state.draw_frame.lightmap_vertex_count += 4;
    }

    // NOTE(Sleepster): building the silhouette of the quads for the light
    for pair_index: 0..light_occluder_pair_count - 1
    {
        light_index    := light_occluder_pairs[pair_index].light_index;
        occluder_index := light_occluder_pairs[pair_index].occluder_index;

        light    := *render_state.engine_point_light_buffer[light_index];
        occluder := *render_state.occluder2D_quad_buffer[occluder_index];
        assert(light != null);

        cell_x: u32 = light.light_atlas_cell_index % (LIGHTMAP_SIZE / MAX_LIGHT_RADIUS);
        cell_y: u32 = light.light_atlas_cell_index / (LIGHTMAP_SIZE / MAX_LIGHT_RADIUS);

        cell_U: float32 = (cast(float32)cell_x * cast(float32)MAX_LIGHT_RADIUS) / LIGHTMAP_SIZE;
        cell_V: float32 = (cast(float32)cell_y * cast(float32)MAX_LIGHT_RADIUS) / LIGHTMAP_SIZE;

        light_cell_scale: float32 = cast(float32)(MAX_LIGHT_RADIUS / LIGHTMAP_SIZE);

        light_mask: [4]float32;
        light_mask.data[light.light_atlas_channel_index] = 1.0;
        
        occluder.top_left.vTexelData     = .{cell_U,                    cell_V};
        occluder.top_right.vTexelData    = .{cell_U + light_cell_scale, cell_V};
        occluder.bottom_left.vTexelData  = .{cell_U,                    cell_V + light_cell_scale};
        occluder.bottom_right.vTexelData = .{cell_U + light_cell_scale, cell_V + light_cell_scale};

        occluder.top_left.vVSNormals     = .{cell_U,                    cell_V,                    0.0};
        occluder.top_right.vVSNormals    = .{cell_U + light_cell_scale, cell_V,                    0.0};
        occluder.bottom_left.vVSNormals  = .{cell_U,                    cell_V + light_cell_scale, 0.0};
        occluder.bottom_right.vVSNormals = .{cell_U + light_cell_scale, cell_V + light_cell_scale, 0.0};

        for *element: occluder.quad_data.elements
        {
            element.vColor     = .{light_mask.data[0], light_mask.data[1], light_mask.data[2], light_mask.data[3]};
        }

        new_occluder := occluder.*;
        for *element: new_occluder.elements
        {
            element.vPosition  = v2_expand(element.vPosition.xy + light.ws_position, 0, 1);
        }

        silhouette_cross_products: [4]float;
        for vertex_index: 0..4 - 1
        {
            vertex0 := occluder.elements[vertex_index].vPosition.xy;
            vertex1 := occluder.elements[(vertex_index + 1) % 4].vPosition.xy;

            edge_vector  := vertex1 - vertex0;
            light_vector := vertex0 - light.ws_position;

            silhouette_cross_products[vertex_index] = v2_cross(edge_vector, light_vector);
        }

        indices: [2]s32;
        count  : u32;
        for value_index: 0..4 - 1 
        {
            value0 := silhouette_cross_products[value_index];
            value1 := silhouette_cross_products[(value_index - 1 + 4) % 4];

            if find_sign(value0) != find_sign(value1)
            {
                indices[xx count] = xx value_index;
                count += 1;

                if count == 2 break;
            }
        }

        cell_offset_x := (cell_x * MAX_LIGHT_RADIUS) - (LIGHTMAP_SIZE * 0.5) + 128;
        cell_offset_y := (cell_y * MAX_LIGHT_RADIUS) - (LIGHTMAP_SIZE * 0.5) + 128;

        cell_min_x := cell_offset_x - (MAX_LIGHT_RADIUS * 0.5);
        cell_min_y := cell_offset_y - (MAX_LIGHT_RADIUS * 0.5);

        cell_max_x := cell_offset_x + (MAX_LIGHT_RADIUS * 0.5);
        cell_max_y := cell_offset_y + (MAX_LIGHT_RADIUS * 0.5);

        edge_vertex0 := occluder.elements[indices[0]].vPosition.xy;
        edge_vertex1 := occluder.elements[indices[1]].vPosition.xy;

        vertex0_light_dir := normalize(edge_vertex0 - light.ws_position);
        vertex1_light_dir := normalize(edge_vertex1 - light.ws_position);

        projection_factor := (Vector2).{256, 256};
        vertex0_proj      := edge_vertex0 + (vertex0_light_dir * projection_factor);
        vertex1_proj      := edge_vertex1 + (vertex1_light_dir * projection_factor);

        edge_vertex0_pos := v2_expand((edge_vertex0 - light.ws_position) + (Vector2).{xx cell_offset_x, xx cell_offset_y}, 0, 1);
        edge_vertex1_pos := v2_expand((edge_vertex1 - light.ws_position) + (Vector2).{xx cell_offset_x, xx cell_offset_y}, 0, 1);
        vertex1_proj_pos := v2_expand((vertex1_proj - light.ws_position) + (Vector2).{xx cell_offset_x, xx cell_offset_y}, 0, 1);
        vertex0_proj_pos := v2_expand((vertex0_proj - light.ws_position) + (Vector2).{xx cell_offset_x, xx cell_offset_y}, 0, 1);

        vertex1_proj_clamp: Vector2 = .{clamp(vertex1_proj_pos.x, cell_min_x, cell_max_x), clamp(vertex1_proj_pos.y, cell_min_y, cell_max_y)};
        vertex0_proj_clamp: Vector2 = .{clamp(vertex0_proj_pos.x, cell_min_x, cell_max_x), clamp(vertex0_proj_pos.y, cell_min_y, cell_max_y)};

        new_occluder.elements[0].vPosition = edge_vertex0_pos;
        new_occluder.elements[1].vPosition = edge_vertex1_pos;
        new_occluder.elements[2].vPosition = v2_expand(vertex1_proj_clamp, 0, 1);
        new_occluder.elements[3].vPosition = v2_expand(vertex0_proj_clamp, 0, 1);

        render_state.occluder2D_vertex_buffer[render_state.draw_frame.occluder_vertex_count + 0] = new_occluder.elements[0];
        render_state.occluder2D_vertex_buffer[render_state.draw_frame.occluder_vertex_count + 1] = new_occluder.elements[1];
        render_state.occluder2D_vertex_buffer[render_state.draw_frame.occluder_vertex_count + 2] = new_occluder.elements[2];
        render_state.occluder2D_vertex_buffer[render_state.draw_frame.occluder_vertex_count + 3] = new_occluder.elements[3];

        render_state.draw_frame.occluder_vertex_count += 4;

        if render_state.draw_frame.occluder_vertex_count >= MAX_GROUP_VERTICES break;
    }
}

        // quad_center_vector := (occluder.elements[0].vPosition.xy + occluder.elements[1].vPosition.xy +
        //                        occluder.elements[2].vPosition.xy + occluder.elements[3].vPosition.xy) * vec2_create(0.25);

        // light_dir_from_quad_center := quad_center_vector - light.ws_position;
        // perpendicular_vector       := (Vector2).{-light_dir_from_quad_center.y, light_dir_from_quad_center.x};

        // vertex_dot_products: [4]float32;
        // for index: 0..4 - 1  
        // {
        //     light_vector              := occluder.elements[index].vPosition.xy - light.ws_position;
        //     vertex_dot_products[index] = dot(light_vector, perpendicular_vector); 
        // }

        // v_min_dot := min(vertex_dot_products[0], vertex_dot_products[1], vertex_dot_products[2], vertex_dot_products[3]);
        // v_max_dot := max(vertex_dot_products[0], vertex_dot_products[1], vertex_dot_products[2], vertex_dot_products[3]);

        // min_vertex_index: s64;
        // max_vertex_index: s64;
        // for index: 0..3
        // {
        //     value := vertex_dot_products[index];
        //     if value == v_min_dot
        //     {
        //         min_vertex_index = index;
        //     }
        //     if value == v_max_dot
        //     {
        //         max_vertex_index = index;
        //     }
        // }

        // v_min := occluder.elements[min_vertex_index].vPosition.xy;
        // v_max := occluder.elements[max_vertex_index].vPosition.xy;

        // projection_factor := (Vector2).{100, 100};
        // v_min_proj: Vector2 = v_min + projection_factor * (v_min - light.ws_position);
        // v_max_proj: Vector2 = v_max + projection_factor * (v_max - light.ws_position);















        // // generate the shadow quad relative to the light and add it to the vertex buffer
        // for vertex_index: 0..4 - 1
        // {
        //     edge0: Vector2 = occluder.elements[vertex_index].vPosition.xy;
        //     edge1: Vector2 = occluder.elements[(vertex_index + 1) % 4].vPosition.xy;

        //     edge0_light_direction_vector: Vector2 = normalize(edge0 - light.ws_position);
        //     edge1_light_direction_vector: Vector2 = normalize(edge1 - light.ws_position);

        //     projection: float32 = light.light_data.radius * 20.0;
        //     edge0_prime := edge0 + (edge0_light_direction_vector * projection);
        //     edge1_prime := edge1 + (edge1_light_direction_vector * projection); 

        //     // TODO(Sleepster): this doesn't have to be a full copy 
        //     new_occluder: Occluder2D;
        //     new_occluder = occluder.*;

        //     new_occluder.elements[0].vPosition = v2_expand(edge0, 0, 1);
        //     new_occluder.elements[1].vPosition = v2_expand(edge1, 0, 1);
        //     new_occluder.elements[2].vPosition = v2_expand(edge1_prime, 0, 1);
        //     new_occluder.elements[3].vPosition = v2_expand(edge0_prime, 0, 1);

        //     render_state.occluder2D_vertex_buffer[render_state.draw_frame.occluder_vertex_count + 0] = new_occluder.elements[0];
        //     render_state.occluder2D_vertex_buffer[render_state.draw_frame.occluder_vertex_count + 1] = new_occluder.elements[1];
        //     render_state.occluder2D_vertex_buffer[render_state.draw_frame.occluder_vertex_count + 2] = new_occluder.elements[2];
        //     render_state.occluder2D_vertex_buffer[render_state.draw_frame.occluder_vertex_count + 3] = new_occluder.elements[3];
