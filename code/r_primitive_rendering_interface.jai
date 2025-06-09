// NOTE(Sleepster): Rotation is stored as degrees, used as radians 
Render_Primitive_Data :: struct
{
    world_position     : Vector2;
    render_size        : Vector2;
    render_color       : Vector4;
    rotation           : float32;
    is_transparent     : s32;

    // NOTE(Sleepster): These are unique to the rendergroup 
    render_pass_id     : u32;
    required_shader_id : u32;
    render_layer       : u32;
    required_texture_id: u32;
    render_texture_idx : u32;

    required_shader    : *GPU_Shader;
    required_material  : *Render_Material;
};

Render_Line :: struct
{
    #as using primitive_data: Render_Primitive_Data;
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
    #as using primitive_data: Render_Primitive_Data;
    union
    {
        elements: [3]Vertex;
        struct
        {
            top_middle  : Vertex;
            bottom_left : Vertex;
            bottom_right: Vertex;
        };
    };
};

Render_Quad :: struct
{
    #as using primitive_data: Render_Primitive_Data;
    union
    {
        elements: [4]Vertex;
        struct
        {
            top_left    : Vertex;
            top_right   : Vertex;
            bottom_left : Vertex;
            bottom_right: Vertex;
        };
    };
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
                       sprite_size   :  Vector2) -> Render_Quad
{
    quad: Render_Quad;
    quad.world_position = position;
    quad.render_size    = render_size;
    quad.render_color   = draw_color;
    quad.rotation       = rotation;
    if quad.render_color.w < 1.0
    {
        quad.is_transparent = 1;
        quad_buffer.t_quad_count += 1;
    }

    if (render_state.draw_frame.active_view_matrix       != render_state.draw_frame.previous_view_matrix) ||
       (render_state.draw_frame.active_projection_matrix != render_state.draw_frame.previous_projection_matrix)
    {
        count := render_state.draw_frame.pass_count;

        render_state.draw_frame.used_projection_matrices[count] = render_state.draw_frame.active_projection_matrix;
        render_state.draw_frame.used_view_matrices[count]       = render_state.draw_frame.active_view_matrix;

        render_state.draw_frame.previous_view_matrix            = render_state.draw_frame.active_view_matrix;
        render_state.draw_frame.previous_projection_matrix      = render_state.draw_frame.active_projection_matrix;

        render_state.draw_frame.pass_count += 1;
    }
    quad.render_pass_id     =  render_state.draw_frame.pass_count - 1;
    quad.required_shader    =  render_state.draw_frame.active_shader;
    quad.required_shader_id =  quad.required_shader.program_id;

    top    := position.y;
    bottom := position.y + render_size.y;
    left   := position.x;
    right  := position.x + render_size.x;

    top_left     := (Vector2).{left,   top};
    top_right    := (Vector2).{right,  top};
    bottom_left  := (Vector2).{left,   bottom};
    bottom_right := (Vector2).{right, bottom};

    quad.required_texture_id     = texture_id;
    quad.render_layer            = render_state.draw_frame.current_render_layer;
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
        element.vVSNormals     = .{0, 0, 1};
    }

    return quad;
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
    current_buffer := r_get_render_group_quad_buffer(render_state);
    render_quad    := r_create_draw_quad(render_state,
                                         current_buffer,
                                         position,
                                         render_size,
                                         draw_color,
                                         texture_id,
                                         rotation,
                                      xx render_options,
                                        (Vector2).{},
                                        (Vector2).{});

    current_buffer.quad_buffer[current_buffer.quad_count] = render_quad;
    current_buffer.quad_count += 1;
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
    render_quad := r_create_draw_quad(render_state,
                                      current_buffer,
                                      position,
                                      render_size,
                                      draw_color,
                                      atlas_sprite.atlas_texture.texID,
                                      rotation,
                                   xx render_options,
                                      v2_cast(atlas_sprite.atlas_offset),
                                      v2_cast(atlas_sprite.atlas_size));

    current_buffer.quad_buffer[current_buffer.quad_count] = render_quad;
    current_buffer.quad_count += 1;
}

// NOTE(Sleepster): Angle is in radians 
r_create_point_light :: (render_state: *Render_State,
                         position    :  Vector2,
                         light_color :  Vector4,
                         direction   :  Vector2,
                         spot_angle  :  float32,
                         radius      :  float32,
                         strength    :  float32 = 1.0) -> *Point_Light
{
    point_light := *render_state.draw_frame.point_light_buffer[render_state.draw_frame.point_light_count];
    point_light.light_color = light_color;

    point_light_pos        := mat4_transform(render_state.draw_frame.active_view_matrix, v2_expand(position, 0, 1));
    point_light.vs_position = point_light_pos.xy;

    point_light.spot_angle  = spot_angle;
    point_light.radius      = radius;
    point_light.direction   = direction;
    point_light.strength    = strength;
    render_state.draw_frame.point_light_count += 1;

    return point_light;
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
