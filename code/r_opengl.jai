/*
TODO(Sleepster):
- [x] Rendering Options
- [x] Texturing
- [ ] Rendering Lines  
- [ ] Allow the renderer to support Point Lights
- [ ] Functions like 'draw_quad_xform()' that would allow XForm placement
- [ ] Resize matrices when the window changes size
*/

MAX_GROUP_VERTICES :: 10000;
MAX_QUADS          :: MAX_GROUP_VERTICES / 4;
MAX_QUAD_INDICES   :: MAX_QUADS * 6;
MAX_LINES          :: MAX_GROUP_VERTICES / 2;
MAX_TRIANGLES      :: #run {cast(s64)(floor(MAX_GROUP_VERTICES / 3));}
MAX_TEXTURE_SLOTS   :: 16;
MAX_RENDER_PASSES   :: 32;
ENGINE_TEXTURE_SIZE :: 2048;

Rendering_Options :: enum u32
{
    RO_NONE          :: 0x00;
    RO_TEXEL_FETCHED :: 0x01;
    RO_UNLIT         :: 0x02;
};

Vertex :: struct
{
    vPosition     : Vector4;
    vColor        : Vector4;
    vTexelData    : Vector2;
    vRenderOptions: u32;
    vTextureIndex : u32;
};

Render_Material :: struct
{
    reflectiveness    : float32;
    illumination_value: float32;
    opacity           : float32;
};

Shader_Uniform_Type :: enum
{
    INVALID_TYPE;
    INTEGER;
    UNSIGNED_INTEGER;
    FLOAT;
    FLOAT_VECTOR2;
    FLOAT_VECTOR3;
    FLOAT_VECTOR4;
    FLOAT_MATRIX3;
    FLOAT_MATRIX4;
    TEXTURE_BINDING;
    TEXTURE_ARRAY;
};

GPU_Shader_Uniform :: struct
{
    location_id   :  s32;
    type          :  Shader_Uniform_Type;
    uniform_name  :  string;

    update_uniform:  (location: s32, data: *void);
    uniform_data  : *void;
};

GPU_Shader_Buffer :: struct
{
    buffer_name   :  string;
    buffer_binding:  u32;

    update_buffer :  (location: u32, size: s64, data: *void);
    buffer_size   :  s64;
    buffer_data   : *void;
};

GPU_Shader_Sampler :: struct
{
    sampler_name   : string;
    sampler_binding: u32;
};

GPU_Shader_Type :: enum
{
    UNDEFINED;
    PIXEL;
    COMPUTE;
};

GPU_Shader :: struct
{
    program_id     :   u32;
    shader_source  :   string;
    shader_type    :   GPU_Shader_Type;

    update_buffer  : (shader: *GPU_Shader, buffer_name : string, size: s64, data: *void);
    update_uniform : (shader: *GPU_Shader, uniform_name: string, data: *void);

    uniform_data   : []GPU_Shader_Uniform;
    buffer_data    : []GPU_Shader_Buffer;
    sampler_data   : []GPU_Shader_Sampler;
};

Draw_Frame :: struct
{
    used_projection_matrices  : [MAX_RENDER_PASSES]Matrix4;
    used_view_matrices        : [MAX_RENDER_PASSES]Matrix4;
    
    active_view_matrix        :   Matrix4;
    active_projection_matrix  :   Matrix4;

    previous_view_matrix      :   Matrix4;
    previous_projection_matrix:   Matrix4;
    pass_count                :   u32;

    bound_texture_counter     :   u32; 
    active_shader             :   GPU_Shader;
    
    // NOTE(Sleepster): Linked Lists 
    quad_buffers              :   Render_Group_Quad_Buffer;
    triangle_buffers          :   Render_Group_Triangle_Buffer;
    line_buffers              :   Render_Group_Line_Buffer;

    render_groups             : []*Render_Group;
    render_group_counter      :   u32;
};

Render_State :: struct
{
    primary_vao_id   : u32;
    primary_vbo_id   : u32;
    primary_ebo_id   : u32;

    test_shader      : GPU_Shader;
    test_shader_projection_matrix: s32;
    test_shader_view_matrix      : s32;

    draw_frame_arena : Memory_Arena;
    render_data_arena: Memory_Arena;
    draw_frame       : Draw_Frame;
};

gl_update_shader_buffer :: inline (location: u32, size: s64, data: *void)
{
    assert(data != null);
    assert(size != 0);

    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, location);
    glBufferSubData(GL_SHADER_STORAGE_BUFFER, 0, size, data);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);
}

gl_update_integer_uniform :: inline (location: s32, data: *void)
{
    assert(data != null);

    value := cast(*s32)data;
    glUniform1i(location, value.*);
}

gl_update_unsigned_integer_uniform :: inline (location: s32, data: *void)
{
    assert(data != null);

    value := cast(*u32)data;
    glUniform1ui(location, value.*);
}

gl_update_float_uniform :: inline (location: s32, data: *void)
{
    assert(data != null);

    value := cast(*float32)data;
    glUniform1f(location, value.*);
}

gl_update_vec2_uniform :: inline (location: s32, data: *void)
{
    assert(data != null);

    value := cast(*Vector2)data;
    glUniform2f(location, value.x, value.y);
}

gl_update_vec3_uniform :: inline (location: s32, data: *void)
{
    assert(data != null);

    value := cast(*Vector3)data;
    glUniform3f(location, value.x, value.y, value.z);
}

gl_update_vec4_uniform :: inline (location: s32, data: *void)
{
    assert(data != null);

    value := cast(*Vector4)data;
    glUniform4f(location, value.x, value.y, value.z, value.w);
}

gl_update_float_mat3_uniform :: inline (location: s32, data: *void)
{
    assert(data != null);

    value := cast(*Matrix3)data;
    glUniformMatrix3fv(location, 1, GL_FALSE, *value._11);
}

gl_update_float_mat4_uniform :: inline (location: s32, data: *void)
{
    assert(data != null);

    value := cast(*Matrix4)data;
    glUniformMatrix4fv(location, 1, GL_FALSE, *value._11);
}

gl_shader_update_buffer :: (shader: *GPU_Shader, buffer_name: string, size: s64, data: *void)
{
    shader_buffer: *GPU_Shader_Buffer;
    for *buffer: shader.buffer_data
    {
        if compare_strings(buffer_name, buffer.buffer_name)
        {
            shader_buffer = buffer;
        }
    }

    if shader_buffer
    {
        shader_buffer.buffer_data = data;
        shader_buffer.buffer_size = size;
    }
    else
    {
        log_error("Invalid shader buffer name... name is: %...\n", buffer_name);
    }
}

gl_shader_update_uniform :: (shader: *GPU_Shader, uniform_name: string, data: *void)
{
    shader_uniform: *GPU_Shader_Uniform;
    for *uniform: shader.uniform_data
    {
        if compare_strings(uniform_name, uniform.uniform_name) == 0
        {
            shader_uniform = uniform;
        }
    }

    if shader_uniform
    {
        assert(shader_uniform.update_uniform != null);
        assert(data != null);

        shader_uniform.update_uniform(shader_uniform.location_id, data);
        shader_uniform.uniform_data = data;
    }
    else
    {
        log_error("Invalid shader uniform name... name is: %...\n", uniform_name);
    }
}

make_shader_object :: (shader: *string, prefix: string, shader_type: GLenum) -> GLuint
{
    LOG_BUFFER_SIZE :: 512;
    shader_object := glCreateShader(shader_type);
    
    shaders: [2]*u8;
    lengths: [2] s32;
    
    shaders[0] = prefix.data;
    shaders[1] = shader.data;
    lengths[0] = xx prefix.count;
    lengths[1] = xx shader.count;
    
    glShaderSource(shader_object, 2, shaders.data, lengths.data);
    glCompileShader(shader_object);
    
    success: GLint;
    glGetShaderiv(shader_object, GL_COMPILE_STATUS, *success);
    
    if !success then
    {
        log_data: [LOG_BUFFER_SIZE] u8;
        glGetShaderInfoLog(shader_object, log_data.count, null, log_data.data);
        log("%", to_string(log_data.data), flags=.ERROR);
        return 0;
    }
    
    return shader_object;
}

compile_pixel_shader :: (arena: *Memory_Arena, shader_text: *string) -> GLuint 
{
    LOG_BUFFER_SIZE :: 512;
    
    PREFIX_V :: #string END
        #version 430 core
        #define VERTEX_SHADER
    END

    PREFIX_F :: #string END
        #version 430 core
        #define FRAGMENT_SHADER
    END
        
    vertex_shader   := make_shader_object(shader_text, PREFIX_V, GL_VERTEX_SHADER);
    fragment_shader := make_shader_object(shader_text, PREFIX_F, GL_FRAGMENT_SHADER);
    program         := glCreateProgram();
    
    glAttachShader(program, vertex_shader);
    glAttachShader(program, fragment_shader);
    glLinkProgram(program);
    
    success: GLint = 0;
    glGetProgramiv(program, GL_LINK_STATUS, *success);
    if !success
    {
        log_data: [LOG_BUFFER_SIZE]u8;
        glGetProgramInfoLog(program, log_data.count, null, log_data.data);
        log_error("%", to_string(log_data.data));
        return 0;
    }
    
    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);
    
    return program;
}

assign_uniform_type :: inline (uniform: *GPU_Shader_Uniform, type: GLenum)
{
    if type ==
    {
        case GL_INT;
        {
            uniform.type           = .INTEGER;
            uniform.update_uniform =  gl_update_integer_uniform;
        };
        case GL_UNSIGNED_INT;
        {
            uniform.type           = .UNSIGNED_INTEGER;
            uniform.update_uniform =  gl_update_unsigned_integer_uniform;
        };
        case GL_FLOAT;
        {
            uniform.type           = .FLOAT;
            uniform.update_uniform =  gl_update_float_uniform;
        };
        case GL_FLOAT_VEC2;
        {
            uniform.type           = .FLOAT_VECTOR2;
            uniform.update_uniform =  gl_update_vec2_uniform;
        };
        case GL_FLOAT_VEC3;
        {
            uniform.type           = .FLOAT_VECTOR3;
            uniform.update_uniform =  gl_update_vec3_uniform;
        };
        case GL_FLOAT_VEC4;
        {
            uniform.type            = .FLOAT_VECTOR4;
            uniform.update_uniform  =  gl_update_vec4_uniform;
        };
        case GL_FLOAT_MAT3;
        {
            uniform.type           = .FLOAT_MATRIX3;
            uniform.update_uniform =  gl_update_float_mat3_uniform;
        };
        case GL_FLOAT_MAT4;
        {
            uniform.type           = .FLOAT_MATRIX4;
            uniform.update_uniform =  gl_update_float_mat4_uniform;
        };
        case GL_SAMPLER_2D;
        {
            uniform.type = .TEXTURE_BINDING;
        };
        case GL_SAMPLER_2D_ARRAY;
        {
            uniform.type = .TEXTURE_ARRAY;
        };
        case;
        {
            log_error("This uniform_type is not supported: '%'...\n", type);
            assert(false);
        };
    };
}

compile_shader_source :: (arena: *Memory_Arena, source: *string, type: GPU_Shader_Type) -> GPU_Shader
{
    shader: GPU_Shader;
    shader.shader_type    = type;
    shader.shader_source  = source.*;
    shader.update_uniform = gl_shader_update_uniform;
    shader.update_buffer  = gl_shader_update_buffer;
    if shader.shader_type ==
    {
        case .PIXEL;
        {
            shader.program_id = compile_pixel_shader(arena, *shader.shader_source);
        }
        case .COMPUTE;
        {
            log_error("Might wanna add compute shader support brother...\n");
        }
        case .UNDEFINED;
        {
            log_error("invalid code path\n\ncompile_shader_source();");
            assert(false);
        }
    }

    if shader.program_id != 0
    {
        // SHADER UNIFORMS
        {
            shader_uniform_count: s32;
            glGetProgramiv(shader.program_id, GL_ACTIVE_UNIFORMS, *shader_uniform_count);
            if shader_uniform_count > 0
            {
                shader.uniform_data = c_arena_push_array(arena, GPU_Shader_Uniform, xx shader_uniform_count);
                for uniform_index: 0..shader.uniform_data.count - 1
                {
                    uniform := *shader.uniform_data[uniform_index];
                    
                    buffer: [256]u8;
                    length: u32;
                    size  : s32;
                    type  : GLenum;
                    glGetActiveUniform(shader.program_id, xx uniform_index, 256, *length, *size, *type, buffer.data);
                    assign_uniform_type(uniform, type);

                    uniform.uniform_name.data  = c_arena_push_size(arena, size_of(u8) * length);
                    uniform.uniform_name.count = length;
                    memcpy(uniform.uniform_name.data, buffer.data, length * size_of(u8));

                    uniform.location_id = glGetUniformLocation(shader.program_id, temp_c_string(uniform.uniform_name));
                }
            }
        }

        // SHADER BUFFERS
        {
            shader_storage_buffer_count: s32;
            glGetProgramInterfaceiv(shader.program_id,
                                    GL_SHADER_STORAGE_BLOCK,
                                    GL_ACTIVE_RESOURCES,
                                   *shader_storage_buffer_count);
            if shader_storage_buffer_count != 0
            {
                shader.buffer_data = c_arena_push_array(arena, GPU_Shader_Buffer, xx shader_storage_buffer_count);
                for GPU_buffer_index: 0..shader.buffer_data.count - 1
                {
                    current_buffer := *shader.buffer_data[GPU_buffer_index];
                    buffer: [256]u8;
                    length: u32;
                    glGetProgramResourceName(shader.program_id,
                                             GL_SHADER_STORAGE_BLOCK,
                                             xx GPU_buffer_index,
                                             256,
                                            *length, buffer.data);
                    current_buffer.buffer_name.data  = c_arena_push_size(arena, size_of(u8) * length);
                    current_buffer.buffer_name.count = length;
                    memcpy(current_buffer.buffer_name.data, buffer.data, size_of(u8) * length);

                    shader_buffer_binding: s32;
                    property: GLenum = GL_BUFFER_BINDING;
                    glGetProgramResourceiv(shader.program_id,
                                           GL_SHADER_STORAGE_BLOCK,
                                           xx GPU_buffer_index,
                                           1,
                                          *property,
                                           1,
                                           null,
                                          *shader_buffer_binding);
                    current_buffer.buffer_binding = xx shader_buffer_binding;
                }
            }
        }
    }
    else
    {
        log_error("Shader program id is invalid...\n");
    }

    return shader;
}

r_upload_texture_to_gpu :: (texture: *Texture2D, filter_type: Filter_Type = .NEAREST, has_AA: bool = false) -> bool
{
    assert(texture.texID == 0);
    assert(texture.bitmap.is_valid);

    if texture.bitmap.is_valid
    {
        glGenTextures(1, *texture.texID);
        glBindTexture(GL_TEXTURE_2D, texture.texID);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        if filter_type ==
        {
            case .NEAREST;
            {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            };
            case .LINEAR;
            {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            };
        }
        if has_AA
        {
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1);
        }

        glTexImage2D(GL_TEXTURE_2D, 0, GL_SRGB8_ALPHA8, 
                     cast(u32)texture.bitmap.width, cast(u32)texture.bitmap.height, 0, 
                     GL_RGBA, GL_UNSIGNED_BYTE, texture.bitmap.data);
        glBindTexture(GL_TEXTURE_2D, 0);

        return true;
    }
    else
    {
        log("[ERROR]: attempted to upload a texture to the GPU with an invalid bitmap...");
        return false;
    }
}

r_update_gpu_texture_from_bitmap :: (texture: *Texture2D) -> bool
{
    assert(texture.texID != 0);
    assert(texture.bitmap.is_valid && texture.bitmap.is_dirty);
    
    glBindTexture(GL_TEXTURE_2D, texture.texID);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    if texture.filter_type ==
    {
        case .NEAREST;
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        }
        case .LINEAR;
        {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        }
    }
    if texture.has_AA
    {
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1);
    }

    glTexImage2D(GL_TEXTURE_2D, 0, GL_SRGB8_ALPHA8, 
                 xx texture.bitmap.width, xx texture.bitmap.height, 0, 
                 GL_RGBA, GL_UNSIGNED_BYTE, texture.bitmap.data);
    glBindTexture(GL_TEXTURE_2D, 0);

    texture.bitmap.is_dirty = false;
    return true;
}

r_init_renderer_data :: (window: *SDL_Window) -> Render_State
{
    // NOTE(Sleepster): GL State Init 
    {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_FRAMEBUFFER_SRGB_CAPABLE, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
        
        gl_context := SDL_GL_CreateContext(window);
        SDL_GL_MakeCurrent(window, gl_context);
        gl_load(*gl, SDL_GL_GetProcAddress);
        gl_enable_debug_output();

        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_GREATER);

        glEnable(GL_FRAMEBUFFER_SRGB);
        print("GL Vendor: %\n", to_string(glGetString(GL_VENDOR)));
        print("GL Version: %\n", to_string(glGetString(GL_VERSION)));

        SDL_GL_SetSwapInterval(0);
    }

    // NOTE(Sleepster): RenderState Init 

    render_state: Render_State;
    {
        render_state.draw_frame_arena  = c_arena_init(MB(200)); 
        render_state.render_data_arena = c_arena_init(MB(100)); 

        // NOTE(Sleepster): quad index buffer setup 
        quad_index_buffer: [MAX_QUAD_INDICES]u32;
        index       : s32;
        index_offset: u32;
        while index < MAX_QUAD_INDICES
        {
            quad_index_buffer[index + 0] = index_offset + 0;
            quad_index_buffer[index + 1] = index_offset + 2;
            quad_index_buffer[index + 2] = index_offset + 1;
            quad_index_buffer[index + 3] = index_offset + 2;
            quad_index_buffer[index + 4] = index_offset + 3;
            quad_index_buffer[index + 5] = index_offset + 0;
            index        += 6;
            index_offset += 4;
        }

        // NOTE(Sleepster): OpenGL state init 
        {
            using render_state;
            glGenVertexArrays(1, *primary_vao_id);
            glBindVertexArray(primary_vao_id);

            glGenBuffers(1, *primary_vbo_id);
            glBindBuffer(GL_ARRAY_BUFFER, primary_vbo_id);
            glBufferData(GL_ARRAY_BUFFER, size_of(Vertex) * MAX_GROUP_VERTICES, null, GL_DYNAMIC_DRAW);

            glGenBuffers(1, *primary_ebo_id);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, primary_ebo_id);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * MAX_QUAD_INDICES, quad_index_buffer.data, GL_STATIC_DRAW);

            T :: Vertex;
            offset: *T: null;
            glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, size_of(Vertex), xx *offset.vPosition);
            glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, size_of(Vertex), xx *offset.vColor);
            glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), xx *offset.vTexelData);

            glVertexAttribIPointer(3, 1, GL_UNSIGNED_INT, size_of(Vertex), xx *offset.vRenderOptions);
            glVertexAttribIPointer(4, 1, GL_UNSIGNED_INT, size_of(Vertex), xx *offset.vTextureIndex);
            
            glEnableVertexAttribArray(0);
            glEnableVertexAttribArray(1);
            glEnableVertexAttribArray(2);
            glEnableVertexAttribArray(3);
            glEnableVertexAttribArray(4);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        }
    }

    render_state.test_shader = compile_shader_source(*render_state.render_data_arena,
                                                     *BASIC_SHADER_SOURCE_TEXT,
                                                     .PIXEL);
    return render_state;
}

#no_reset uploaded_debug_texture: bool = false;
r_render_group_test_render :: (render_state: *Render_State, asset_manager: *Asset_Manager)
{
    render_state.draw_frame.active_shader            = render_state.test_shader;
    render_state.draw_frame.active_view_matrix       = mat4_identity();
    render_state.draw_frame.active_projection_matrix = orthographic_projection_matrix(1920 * -0.5,
                                                                                      1920 *  0.5,
                                                                                      1080 * -0.5,
                                                                                      1080 *  0.5,
                                                                                     -1.0,
                                                                                      1.0);
    r_draw_quad(render_state, .{  10,   10}, .{100, 100}, .{1, 0, 0, 1}, U32_MAX, .RO_NONE, deg_to_rad(140));
    r_draw_quad(render_state, .{-100, -100}, .{100, 100}, .{0, 1, 0, 1});
    r_draw_quad(render_state, .{ 100,    0}, .{100, 100}, .{0, 0, 1, 1});
    r_draw_quad(render_state, .{ 100,  150}, .{100, 100}, .{1, 0, 1, 1});

    
    sprite  := asset_get_sprite(asset_manager, "player");
    texture := asset_get_texture(asset_manager, "player");
    if !uploaded_debug_texture
    {
        if texture
        {
            uploaded_debug_texture = r_upload_texture_to_gpu(texture);
            if !uploaded_debug_texture 
            {
                log("Error...\n");
            }
        }
    }
    r_draw_sprite(render_state, .{-200,  150}, .{100, 100}, .{1, 1, 1, 1}, sprite, deg_to_rad(140));
    r_draw_quad(render_state,   .{ 200,  150}, .{100, 100}, .{0, 1, 0, 1}, texture.texID, 0);
    r_draw_quad(render_state,   .{ 200, -150}, .{100, 100}, .{0, 0, 1, 1}, texture.texID, 0);
    r_draw_quad(render_state,   .{-200, -150}, .{100, 100}, .{1, 1, 1, 1}, texture.texID, .RO_NONE, deg_to_rad(33));
    
    glViewport(0, 0, 1920, 1080);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClearDepth(0.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    glBindVertexArray(render_state.primary_vao_id);

    r_handle_group_buffers(render_state);
    for group_index: 0..render_state.draw_frame.render_group_counter - 1
    {
        working_group := render_state.draw_frame.render_groups[group_index];
        working_group.bound_shader.update_uniform(*working_group.bound_shader,
                                                  "ProjectionMatrix",
                                                  *working_group.projection_matrix._11);
        working_group.bound_shader.update_uniform(*working_group.bound_shader,
                                                  "ViewMatrix",
                                                  *working_group.view_matrix._11);
        
        glBindBuffer(GL_ARRAY_BUFFER, render_state.primary_vbo_id);
        glBufferSubData(GL_ARRAY_BUFFER,
                        0,
                        working_group.vertex_count * size_of(Vertex),
                        working_group.vertex_buffer.data);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, render_state.primary_ebo_id);

        shader := *working_group.bound_shader;
        glUseProgram(shader.program_id);
        
        for uniform_index: 0..shader.uniform_data.count - 1
        {
            uniform := *shader.uniform_data[uniform_index];
            if uniform.type != .TEXTURE_BINDING && uniform.type != .TEXTURE_ARRAY
            {
                if uniform.update_uniform != null
                {
                    uniform.update_uniform(uniform.location_id, uniform.uniform_data);
                }
            }
            else
            {
                if working_group.group_texture_count > 0
                {
                    if uniform.type == .TEXTURE_BINDING
                    {
                        for texture_index: 0..working_group.group_texture_count - 1
                        {
                            texture_id := working_group.texture_ids[texture_index];
                            glActiveTexture(GL_TEXTURE0 + texture_id);
                            glBindTexture(GL_TEXTURE_2D, texture_id);
                        }
                        
                        sampler_units: [MAX_TEXTURE_SLOTS]s32;
                        for binding: 0..MAX_TEXTURE_SLOTS - 1
                        {
                            sampler_units[binding] = xx binding;
                        }
                        glUniform1iv(uniform.location_id, MAX_TEXTURE_SLOTS, sampler_units.data);
                    }
                    else
                    {
                        // TODO(Sleepster): This doesn't actually work... 
                        assert(uniform.type == .TEXTURE_ARRAY);
                        if uniform.location_id != -1
                        {
                            for texture_index: 0..working_group.group_texture_count - 1
                            {
                                texture_id := working_group.texture_ids[texture_index];
                                glActiveTexture(GL_TEXTURE0 + texture_id);
                                glBindTexture(GL_TEXTURE_2D, texture_id);
                            }
                            
                            sampler_units: [MAX_TEXTURE_SLOTS]s32;
                            for binding: 0..MAX_TEXTURE_SLOTS - 1
                            {
                                sampler_units[binding] = xx binding;
                            }
                            glUniform1iv(uniform.location_id, MAX_TEXTURE_SLOTS, sampler_units.data);
                        }
                    }
                }
            }
        }

        for buffer_index: 0..shader.buffer_data.count - 1
        {
            shader_buffer := *shader.buffer_data[buffer_index];
            shader_buffer.update_buffer(shader_buffer.buffer_binding,
                                        shader_buffer.buffer_size,
                                        shader_buffer.buffer_data);
        }

        glDrawElements(GL_TRIANGLES,
                       working_group.current_quad_count * 6,
                       GL_UNSIGNED_INT,
                       null);
    }
}

r_reset_draw_frame :: inline (render_state: *Render_State)
{
    c_arena_reset(*render_state.draw_frame_arena);
    render_state.draw_frame = .{};
}
