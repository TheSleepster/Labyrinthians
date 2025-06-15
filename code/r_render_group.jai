Render_Group_Flags :: enum
{
    USES_FORWARD;
    NO_LIGHTING;
    NO_SHADOWS;
};

// NOTE(Sleepster): This is the only primitive type to make use of an index buffer. The rest don't need it. 
Render_Group_Quad_Buffer :: struct
{
    is_initialized: bool;
    
    vertex_buffer: []Vertex;
    vertex_count :   u32;

    quad_buffer  : []Render_Quad;
    quad_count   :   u32;
    t_quad_count :   u32;

    next_buffer  : *Render_Group_Quad_Buffer;
};

Render_Group_Triangle_Buffer :: struct
{
    vertex_buffer  : []Vertex;
    vertex_count   :   u32;

    triangle_buffer: []Render_Triangle;
    triangle_count :   u32;

    next_buffer    : *Render_Group_Triangle_Buffer;
};

Render_Group_Line_Buffer :: struct
{
    vertex_buffer: []Vertex;
    vertex_count :   u32;

    line_buffer  : []Render_Line;
    line_count   :   u32;

    next_buffer  : *Render_Group_Line_Buffer;
};

Render_Group :: struct
{
    group_id: u32;

    vertex_buffer      : []Vertex;
    vertex_count       :   u32;
    
    quad_render_buffer : []Render_Quad;
    current_quad_count :   u32;
    t_quad_count       :   u32;
    
    triangle_buffer_ptr: *Render_Triangle;
    triangle_count     :  u32;

    line_buffer_ptr    : *Render_Line;
    line_count         :  u32;
    
    texture_ids        : [MAX_TEXTURE_SLOTS]u32;
    group_texture_count:  u32; 
    bound_textures     :  u32;

    stored_render_layer:  u32;
    view_matrix        :  Matrix4;
    projection_matrix  :  Matrix4;
    bound_material     : *Render_Material;
    bound_shader       : *GPU_Shader;
};

r_create_new_render_group :: (render_state           : *Render_State,
                              render_group_hash_table: []*Render_Group,
                              working_quad           : *Render_Quad,
                              hash_value             : s64) -> *Render_Group
{
    hash_render_group := c_arena_push_struct(*render_state.draw_frame_arena, Render_Group);
    render_group_hash_table[hash_value] = hash_render_group;

    draw_frame := *render_state.draw_frame;
    hash_render_group.* = .{};
    hash_render_group.view_matrix         = draw_frame.used_view_matrices[working_quad.quad_render_matrix_id];
    hash_render_group.projection_matrix   = draw_frame.used_projection_matrices[working_quad.quad_render_matrix_id];
    hash_render_group.bound_shader        = working_quad.required_shader;
    hash_render_group.stored_render_layer = working_quad.render_layer;
    hash_render_group.bound_material      = working_quad.required_render_material;

    // TODO(Sleepster): Is this an issue??? Likely not. It's only 150KB per MAX_QUADS...
    hash_render_group.quad_render_buffer = c_arena_push_array(*render_state.draw_frame_arena, Render_Quad, MAX_QUADS);
    hash_render_group.group_id           = xx hash_value;

    render_state.draw_frame.render_groups[draw_frame.render_group_counter] = hash_render_group;
    render_state.draw_frame.render_group_counter += 1;

    return hash_render_group;
}

r_get_render_group_quad_buffer :: (render_state: *Render_State) -> *Render_Group_Quad_Buffer
{
    start_buffer   := *render_state.draw_frame.quad_buffers;
    current_buffer: *Render_Group_Quad_Buffer = start_buffer;
    while current_buffer != null
    {
        if current_buffer.quad_count < MAX_QUADS
        {
            break;
        }

        if current_buffer.next_buffer == null
        {
            current_buffer.next_buffer = c_arena_push_struct(*render_state.draw_frame_arena,
                                                              Render_Group_Quad_Buffer);
        }

        current_buffer = current_buffer.next_buffer;
    }
    assert(current_buffer != null);

    if !current_buffer.is_initialized
    {
        current_buffer.quad_buffer   = c_arena_push_array(*render_state.draw_frame_arena, Render_Quad, MAX_QUADS);
        current_buffer.vertex_buffer = c_arena_push_array(*render_state.draw_frame_arena, Vertex,      MAX_GROUP_VERTICES);

        current_buffer.is_initialized = true;
    }
    assert(current_buffer.quad_buffer.data   != null);
    assert(current_buffer.vertex_buffer.data != null);

    return current_buffer;
}

r_hash_quad_value :: (shader_id: u32, pass_id: u32, render_layer: u32, render_material_ptr: *u32, max_entries: u64) -> s64
{
    hash     : u64 = 14695981039346656037; 
    fnv_prime: u64 = 1099511628211;

    mat_value := render_material_ptr.*;

    hash = hash ^ cast(u64)render_layer;
    hash = hash * fnv_prime;

    hash = hash ^ cast(u64)shader_id;
    hash = hash * fnv_prime;

    hash = hash ^ cast(u64)pass_id;
    hash = hash * fnv_prime;

    hash = hash ^ cast(u64)mat_value;
    hash = hash * fnv_prime;

    return xx((hash % max_entries + max_entries) % max_entries);
}

add_texture_to_render_group_list :: (render_group: *Render_Group, texture_id: u32)
{
    for tex_id: render_group.texture_ids
    {
        if texture_id == tex_id then return;
    }
    assert(render_group.group_texture_count + 1 < MAX_TEXTURE_SLOTS);
    
    render_group.texture_ids[render_group.group_texture_count] = texture_id;
    render_group.group_texture_count += 1;
}

// IMPORTANT(Sleepster): PRIME NUMBER 
MAX_RENDER_GROUPS :: 1021;

// NOTE(Sleepster): This function is used to work to set up the amount of render groups we need
r_handle_group_buffers :: (render_state: *Render_State)
{
    d_profile_scope();
    draw_frame := *render_state.draw_frame;

    // TODO(Sleepster): Check if this hash needs to be larger 
    draw_frame.render_groups = c_arena_push_array(*render_state.draw_frame_arena, *Render_Group, MAX_RENDER_GROUPS);
    render_group_hash_table := c_arena_push_array(*render_state.draw_frame_arena, *Render_Group, MAX_RENDER_GROUPS * 4);

    current_quad_buffer := *draw_frame.quad_buffers;
    while current_quad_buffer != null
    {
        scratch_buffer  := c_arena_begin_temporary_memory(*render_state.draw_frame_arena);

        // NOTE(Sleepster): WOW This is stupid but idc, since it's probably faster than memset anyway...
        sorting_buffer  := c_arena_push_array(*render_state.draw_frame_arena, Render_Quad, current_quad_buffer.quad_count);
        sorting_buffer2 := c_arena_push_array(*render_state.draw_frame_arena, Render_Quad, current_quad_buffer.quad_count);
        sorting_buffer3 := c_arena_push_array(*render_state.draw_frame_arena, Render_Quad, current_quad_buffer.quad_count);
        sorting_buffer4 := c_arena_push_array(*render_state.draw_frame_arena, Render_Quad, current_quad_buffer.quad_count);
        sorting_buffer5 := c_arena_push_array(*render_state.draw_frame_arena, Render_Quad, current_quad_buffer.quad_count);
        
        radix_sort(current_quad_buffer.quad_buffer.data,
                   sorting_buffer.data,
                xx current_quad_buffer.quad_count,
                   size_of(Render_Quad), 
                xx offset_of(Render_Quad, #code required_shader_id),
                   4);

        radix_sort(current_quad_buffer.quad_buffer.data,
                   sorting_buffer2.data,
                xx current_quad_buffer.quad_count,
                   size_of(Render_Quad), 
                xx offset_of(Render_Quad, #code quad_render_matrix_id),
                   4);

        radix_sort(current_quad_buffer.quad_buffer.data,
                   sorting_buffer3.data,
                xx current_quad_buffer.quad_count,
                   size_of(Render_Quad), 
                xx offset_of(Render_Quad, #code render_layer),
                   4);

        if draw_frame.bound_texture_counter > 1
        {
            radix_sort(current_quad_buffer.quad_buffer.data,
                       sorting_buffer4.data,
                    xx current_quad_buffer.quad_count,
                       size_of(Render_Quad), 
                    xx offset_of(Render_Quad, #code required_texture_id),
                       4);
        }

        radix_sort(current_quad_buffer.quad_buffer.data,
                   sorting_buffer5.data,
                xx current_quad_buffer.quad_count,
                   size_of(Render_Quad),
                xx offset_of(Render_Quad, #code is_transparent),
                   2);
        
        c_arena_end_temporary_memory(*scratch_buffer);
        current_quad_buffer = current_quad_buffer.next_buffer;
    }
    
    current_quad_buffer = *draw_frame.quad_buffers;
    while current_quad_buffer != null
    {
        for quad_index: 0..current_quad_buffer.quad_count - 1
        {
            working_quad := *current_quad_buffer.quad_buffer[quad_index];
            hash_value   := r_hash_quad_value(working_quad.required_shader.program_id,
                                              working_quad.quad_render_matrix_id,
                                              working_quad.render_layer,
                                              cast(*u32)working_quad.required_render_material,
                                              MAX_RENDER_GROUPS);
            hash_render_group: *Render_Group = render_group_hash_table[hash_value];
            if hash_render_group == null
            {
                hash_render_group = r_create_new_render_group(render_state,
                                                              render_group_hash_table,
                                                              working_quad,
                                                              hash_value);
            }
            assert(hash_render_group.group_id != 0 &&
                   hash_render_group.group_id == hash_value);

            if working_quad.required_texture_id != U32_MAX 
            {
                add_texture_to_render_group_list(hash_render_group, working_quad.required_texture_id);
            }

            if hash_render_group.current_quad_count + 1 >= MAX_QUADS
            {
                assert(hash_render_group != null);
                hash_render_group = null;

                hash_render_group = r_create_new_render_group(render_state,
                                                              render_group_hash_table,
                                                              working_quad,
                                                              hash_value);
            }
            else
            {
                hash_render_group.quad_render_buffer[hash_render_group.current_quad_count] = working_quad.*;
                hash_render_group.current_quad_count += 1;
            }
        }

        current_quad_buffer = current_quad_buffer.next_buffer;
    }

    for group_index: 0..draw_frame.render_group_counter - 1
    {
        working_group := draw_frame.render_groups[group_index];
        if working_group != null
        {
            working_group.vertex_buffer = c_arena_push_array(*render_state.draw_frame_arena,
                                                             Vertex,
                                                             working_group.current_quad_count * 4);
            for quad_index: 0..working_group.current_quad_count - 1
            {
                working_quad      := *working_group.quad_render_buffer[quad_index];
                vertex_buffer_ptr := *working_group.vertex_buffer[working_group.vertex_count];
                if working_quad.is_transparent
                {
                    working_group.t_quad_count += 1;
                }

                bottom_left : *Vertex = vertex_buffer_ptr + 0;
                top_left    : *Vertex = vertex_buffer_ptr + 1;
                top_right   : *Vertex = vertex_buffer_ptr + 2;
                bottom_right: *Vertex = vertex_buffer_ptr + 3;
                working_group.vertex_count += 4;

                top_left.*     = working_quad.top_left;
                top_right.*    = working_quad.top_right;
                bottom_left.*  = working_quad.bottom_left;
                bottom_right.* = working_quad.bottom_right;
            }
        }
    }
    
    // NOTE(Sleepster): Final sort to ensure draw order 
    group_sorting_buffer := c_arena_push_array(*render_state.draw_frame_arena,
                                                Render_Group,
                                                draw_frame.render_group_counter);
    radix_sort(draw_frame.render_groups.data,
               group_sorting_buffer.data,
               xx draw_frame.render_group_counter,
               size_of(Render_Group), 
               xx offset_of(Render_Group, #code stored_render_layer),
               8);
}
