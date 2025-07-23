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

/*
* TODO(Sleepster): 
* PROBLEM:
*
* We have a problem with the initial philosophy of this renderer. The
* problem is that although we can control things like what shader is
* applied to the contents of the render group we cannot control what
* effects get applied to the render_group itself. We also only group
* quads by their required shaders when we should be grouping them by
* their required effects. Since I thought about it, it makes no sense
* for quads that take on lighting effects to be rendered with quads
* that don't want any such effect. It just leads to a conflict of
* interest. 
*
* GOAL:
*
* Group data differently, currnently we group quads by their required
* textures or shaders. Instead we need to group them by effects. We
* whould also give the user more control over how the rendering
* currently works and modify the api to take a new approach, one that
* expands the api into allowing us to create render_passes that
* control what effects are applied and how. Create something like a
* render_pass_desc that contains the information needed to properly
* render items appropriately. All the rendering is done in a "deferred
* way" where these render_groups (or render_passes) are meant to store
* the data intermediately about how items should be rendered so that
* they can LATER be rendered using the OpenGL backend later.
*
* SOLUTION:
*
* 1.) ---Modify how render_groups store data, and how that data is grouped---
*     
*     Instead of storing the quads in a quad_buffer that uses a
*     linked list to support an infinite amount of quads for all
*     rendering passes, why not just bake these quad_buffers into the
*     render groups themselves using calls like "begin_render_pass"
*     and "end_render_pass" to allow us to effectively store the
*     quads as part of the render group. This will not only save us CPU time
*     sorting the quads into the correct group since they are already
*     in the group that they need to be inside of but also allow us to use
*     runtime error checking to make sure that a quad that you insert
*     into the quad buffer of a render_group matches the rest of the
*     data for the render_pass.
*
* 2.) ---Consider batching by effect and along with the required shader. Handling effects needed later in the pipeline---
*     
*     Allow the user to create a render_group and supply a
*     "render_pass_desc" that will allow us to label the render_pass with
*     effect data like "RE_Lighting" or "RE_Bloom" or let the user
*     change the blend_mode for that specific draw call. This would
*     give the user more control and would expand the settings that we
*     currently allow. Settings like these would also allow us to
*     change how our rendering currently happens since we could just
*     apply the effects in a seperate in-engine pass that simply would
*     build on top of the data the user provides.
*
* 3.) ---Create the custom in-engine passes to act upon the data as desired by the render_pass_desc---
*     
*     Once the rendering of all passes is complete, we iterate through all
*     the render_groups to find out which of the effects and how many
*     effects each render_group wants applied to the geometry they
*     store. Then we will perform the post processing on their data as
*     requested once at the very end of the pipeline, thus gracefully
*     and efficiently handling the desired effects in a way that
*     doesn't cause nearly as much overdraw as the methods we
*     currently employ in our shaders while also allowing us to create
*     custom "bloom_pass.glsl" shaders and also allows the user to
*     slightly modify these shaders if they so desire while expanding
*     and upgrading the pipeline significantly while preventing the
*     current problem of shader handling.
*  
* 
* RUNTIME ERROR CHECKING FOR GROUPS:
* - When adding an item to a render_group make sure the effect bits
*   support what we are currently attempting to render.
*
*
* BONUS:
* MULTITHREADING
*    Perhaps when we transfer the vertices from the quad buffer -> render_group's vertex buffer 
*    we could parallelize it to work on multiple groups at once using a job system.
* 
* THE PROCESS OF RENDERING A QUAD:
*     1.) There are a few things that need to be done before we can
*         actually draw a quad. The first thing is that we can't draw a quad
*         without first having a render_group created, so we need to bind one
*         for use. The process of doing this looks like so:
*
*            - Create a "render_pass_desc" and fill it out. The
*              render_pass_desc will contain data about what blendmode the
*              pass need, what shader_id it desires for rendering, what
*              layer it will be rendered on, what matrices it would like
*              to render with, and what effects it would like the items
*              within it to take on. After this struct has been filled out
*              we will call the function "begin_render_pass()" and pass in
*              the pointer to our "render_pass_desc". Using this
*              "render_pass_desc" we will search the array of already
*              generated render_groups to see if any of the already made
*              render_groups suit the requirements needed by comparing
*              their "render_pass_desc". If it finds an already made
*              "render_group" that matches the "render_pass_desc" we pass,
*              we will set the pointer in our "draw_frame_data" struct for
*              "active_render_pass" to the render_group desired. If there
*              is a not a "render_group" that matches our
*              "render_pass_desc", then we create a new one and add it to
*              the array of created "render_group"s setting that same
*              "draw_frame_data" pointer to the pointer of this newly
*              generated "render_group".
*
*     2.) After the "active_render_group" has been assigned, we can now
*         call "draw_quad" with the information needed to render the
*         quad. If the quad is textured we add it to the list of textures
*         needed to draw the items in the "render_group". Should the
*         number of textures exceed a certain set amount we will simply
*         through a runtime error for the user. "draw_quad" will then add
*         the quad's data to this "render_group", deferred the actual
*         render process to later. Think of this as a "quad gathering"
*         stage where we get all the data we want to render over the
*         course of the frame, then prepare to render these quads at the
*         very end of the frame.
*
*     3.) Finally, at the very end of the game frame before all the data
*         gets rendered by the backend graphics API we process the quads
*         inside of the quad buffers, transferring their vertex data from
*         the "render_quad" container to the render_group's vertex
*         buffer. Once this is done the group is ready to be passed along
*         to the graphics api backend.
*     
*     4.) When you're done rendering with this render_pass_desc, you can
*         call "end_render_pass()" which will set the "acitve_render_pass"
*         to null.
*
*
*  
* A NOTE ABOUT THIS METHOD:
*    - This approach also allows us to give the user the ability to
*      slightly modify the shaders used for the effect stages. While
*      the user will have to keep the same type of template for the
*      effect (meaning they won't be able to change what textures are
*      bound or what vertex attributes are present, they will still be
*      able to change how the effect is applied in the shader) but the
*      ability and freedom to adjust these passes is still present
*
*      We should also allow the user to create a "pipeline_desc" which will
*      tell us what order the effects should be applied and what their
*      individually intensities are. Intensities tell us how strong the
*      effect is on it's framebuffer along with how much influence it has
*      when being composited. 
*
* THE FULL BACKEND GRAPHICS PIPELINE:
*    STAGES:
*    1.) Draw all the "render_group" items that were created here in
*        their desired order, treating them as their own
*        renderpasses. We will render transparent objects in this way
*        as well. We do this because we are in 2D and the render order
*        must be preserved. The rendering will bind their needed
*        shaders, textures, and other data needed for required shader
*        renderering the scene using a forward renderer. This pass
*        will render everything into a framebuffer of a size the user
*        requests and will have no effects present in this rendered
*        framebuffer, instead deferring the application of these
*        effects later on into the pipeline.
*
*     2.) We will then loop through all of the "render_group" and check
*        what effects each of these render_groups would like to have
*        applied to them, calling a function that will apply the effect as
*        desired, rendering these effects into their own framebuffer. Each
*        effect will have it's own framebuffer. For example, Lighting will
*        have a different framebuffer from that of bloom due to the
*        different requirements for rendering they might have. We will
*        do this by rendering the objects from the original pass (pass
*        1) into a buffer where the shader will control how the effect
*        gets applied. This effect will not be applied directly to the
*        same framebuffer as pass 1 because we may want to be able to
*        control how effects mix. (like how bloom would mix with film
*        grain). We may in the future create a system that is able to
*        process different effects in the same framebuffer, but this
*        seems like a bad idea to me due to the shaders and scene
*        graphing we'd have to do. 
*         NOTE: Effects that could be able to be rendered together in the same
                framebuffer would be. (example: tonemapping and
                colorgrading. Just generally effects that don't need to be
                independant of one another).
*      
*     3.) Then in this final pass we'll have some different functions that
*         once again control how the effects get applied to the main game
*         framebuffer. These contributions will also have their "contribution
*         strengths" controllable through shader constants allowing us to
*         configure how the effects get applied to this final pass, which will
*         then get overlayed with the game framebuffer.
*    
*     4.) Lastly if the target window and the game framebuffer do not
*         match in resolution we will blit the result to the screen,
*         displaying the final output of the render pipeline to the
*         screen.
*/

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
    hash_render_group.view_matrix          = draw_frame.used_view_matrices[working_quad.quad_render_matrix_id];
    hash_render_group.projection_matrix    = draw_frame.used_projection_matrices[working_quad.quad_render_matrix_id];
    hash_render_group.bound_shader         = working_quad.required_shader;
    hash_render_group.stored_render_layer  = working_quad.render_layer;
    hash_render_group.bound_material       = working_quad.required_render_material;

    // TODO(Sleepster): Is this REALLY what we want here? Not all
    // render_groups will make use of it, and a 4kx4k texture is
    // expensive to bind
    hash_render_group.texture_ids[0]       = render_state.sfb_lightmap;
    hash_render_group.group_texture_count += 1;

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

    if draw_frame.quad_buffers.quad_count == 0
    {
        return;
    }

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

    // TODO(Sleepster): Multithreading 
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
