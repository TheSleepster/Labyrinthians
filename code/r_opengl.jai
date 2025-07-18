/*
TODO(Sleepster):
- [x] Rendering Options
- [x] Texturing
- [x] Allow the renderer to support Point Lights
- [x] add a "light_strength" field to point lights to brighten or dim the light
- [x] remove the old 'Light_Attenuation_Data' field from the Point_Light 
- [x] render_options for allowing objects to remain unaffected by both ambient and point lights
- [x] allow the user to control the angle of the light
- [x] Lightmap. Render all lights into a seperate texture and then mix the two textures together at the end of the final renderpass
- [x] stencil buffer and shadows
- [ ] Rendering Lines  
- [ ] Functions like 'draw_quad_xform()' that would allow XForm placement
- [ ] Resize matrices when the window changes size
- [ ] Build a proper debug Profiler (graphs, ui, the works)

LONG TERM:
- [ ] Light and occluder groups (like render_groups) to avoid overflow
*/

MAX_GROUP_VERTICES          :: 10000;
MAX_QUADS                   :: MAX_GROUP_VERTICES / 4;
MAX_QUAD_INDICES            :: MAX_QUADS * 6;

MAX_LINES                   :: MAX_GROUP_VERTICES / 2;
MAX_TRIANGLES               :: #run {cast(s64)(floor(MAX_GROUP_VERTICES / 3));}

MAX_TEXTURE_SLOTS           :: 16;
MAX_RENDER_PASSES           :: 32;
MAX_LIGHTS_PER_TILE_CLUSTER :: 64;
ENGINE_TEXTURE_SIZE         :: 2048;

MAX_LIGHTS                  :: MAX_QUADS; 
MAX_OCCLUDERS               :: MAX_QUADS;

MAX_LIGHT_RADIUS            :: 256;
LIGHTMAP_SIZE               :: 4096;

r_default_render_material: *Render_Material;

#no_reset uploaded_debug_texture: bool = false;

// TODO(Sleepster): Put this somewhere safe. 
#no_reset ambient_factor: float32 = 0.3;

// NOTE(Sleepster): VS = view space 
Shader_Light_Data :: struct
{
    light_color: Vector4;
    light_mask : Vector4;
    padding_0  : [2]float32;
    atlas_uvs  : Vector2;
    vs_position: Vector2;
    cs_position: Vector2;
    direction  : Vector2;
    spot_angle : float32;
    radius     : float32;
    strength   : float32;
    padding_1  : [3]float32;
}#no_padding;

Point_Light :: struct
{
    light_data               : *Shader_Light_Data;
    ws_position              :  Vector2;

    light_atlas_cell_index   :  u32;
    light_atlas_channel_index:  u32;
    light_buffer_index       :  u32;
};

/*
TODO(Sleepster): Maybe we don't need texelFetch? Maybe it's even better to not have it

https://jorenjoestar.github.io/post/pixel_art_filtering/
https://youtu.be/Yu8k7a1hQuU?si=RGvJRsBsLU9JyWVw&t=5473

However it might not work better specifically with OpenGL since the driver
might interperet the texels with a 0.5 texel of error. OpenGL sucks.

https://handmade.network/forums/t/7883-pixel_art_fragment_shader
*/

Rendering_Options :: enum u32
{
    RO_NONE          :: 0x00;
    RO_TEXEL_FETCHED :: 0x01;
    RO_UNLIT         :: 0x02;
    RO_OCCLUDER      :: 0x04;
};

Vertex :: struct
{
    vPosition     : Vector4;
    vColor        : Vector4;
    vVSNormals    : Vector3;
    vTexelData    : Vector2;
    vRenderOptions: u32;
    vTextureIndex : u32;
    vRenderLayer  : u32;
}#no_padding;

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

// TODO(Sleepster): Buffer Type (STATIC, DYNAMIC, STREAM)? 
GPU_Shader_Buffer_Config :: struct
{
    buffer_name: string;
    size_init  : s64;
    read_only  : bool;
};

GPU_Shader_Buffer :: struct
{
    buffer_name   :  string;
    buffer_binding:  u32;
    location_id   :  u32;
    read_only     :  bool;

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
    program_id       :   u32;
    shader_source    :   string;
    hash_name        :   string;
    shader_type      :   GPU_Shader_Type;

    uniform_data     : []GPU_Shader_Uniform;
    UBO_buffer_data  : []GPU_Shader_Buffer;
    SBO_buffer_data  : []GPU_Shader_Buffer;
    SBO_buffer_config: []GPU_Shader_Buffer_Config;

    sampler_data     : []GPU_Shader_Sampler;
};

Draw_Frame :: struct
{
    used_projection_matrices  : [MAX_RENDER_PASSES]Matrix4;
    used_view_matrices        : [MAX_RENDER_PASSES]Matrix4;

    previous_view_matrix      :   Matrix4;
    previous_projection_matrix:   Matrix4;
    current_render_matrix_id  :   u32;

    bound_texture_counter     :   u32; 

    active_view_matrix        :   Matrix4;
    active_projection_matrix  :   Matrix4;
    active_shader             :  *GPU_Shader;
    active_render_material    :  *Render_Material;
    current_render_layer      :   u32;

    render_groups             : []*Render_Group;
    render_group_counter      :   u32;

    // NOTE(Sleepster): Linked Lists 
    quad_buffers              :   Render_Group_Quad_Buffer;
    triangle_buffers          :   Render_Group_Triangle_Buffer;
    line_buffers              :   Render_Group_Line_Buffer;

    light_atlas_channel_index :   u32;
    light_atlas_cell_index    :   u32;

    lightmap_vertex_count     :   u32;

    occluder_vertex_count     :   u32;
    occluder2D_count          :   u32;
    
    light_count               :   u32;
};

Render_State :: struct
{
    primary_vao_id                 : u32;
    primary_vbo_id                 : u32;
    primary_ebo_id                 : u32;

    render_data_arena              : Memory_Arena;
    draw_frame_arena               : Memory_Arena;

    draw_frame                     : Draw_Frame;

    occluder2D_vertex_buffer       : []Vertex;
    occluder2D_quad_buffer         : []Occluder2D;

    lightmap_vertex_buffer         : []Vertex;
    lightmap_quad_buffer           : []Render_Quad;

    shader_point_light_buffer      : []Shader_Light_Data;
    engine_point_light_buffer      : []Point_Light;

    update_buffer    : (shader: *GPU_Shader, buffer_name : string, size    : s64, data: *void);
    resize_shader_buf: (shader: *GPU_Shader, buffer_name : string, new_size: s64);
    update_uniform   : (shader: *GPU_Shader, uniform_name: string, data    : *void);
    update_UBO       : (shader: *GPU_Shader, UBO_name    : string, data    : *void);

    shadow_pass_shader: *GPU_Shader;
    lightmap_shader   : *GPU_Shader;
    composite_shader  : *GPU_Shader;
};

// TODO(Sleepster): speed... 
gl_resize_SSBO :: (shader: *GPU_Shader, buffer_name: string, new_size: s64)
{
    buffer_config: *GPU_Shader_Buffer_Config;
    buffer:        *GPU_Shader_Buffer;
    for *config: shader.SBO_buffer_config
    {
        if compare_strings(buffer_name, config.buffer_name) == 0
        {
            buffer_config = config;
        }
    }

    for *a_buffer: shader.SBO_buffer_data
    {
        if compare_strings(buffer_name, a_buffer.buffer_name) == 0
        {
            buffer = a_buffer;
        }
    }

    if buffer_config != null && buffer != null
    {
        buffer_config.size_init = new_size;

        // TODO(Sleepster): Maybe add the ability to control what the update frequency of the buffer should be...
        // IE. add the ability to set: GL_STATIC_DRAW GL_STREAM_DRAW GL_DYNAMIC_DRAW
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, buffer.location_id);
        glBufferData(GL_SHADER_STORAGE_BUFFER, buffer_config.size_init, null, GL_STREAM_DRAW);

        glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);
    }
    else
    {
        log("[ERROR]: buffer_name of '%' is not valid...\n", buffer_name);
        assert(false);
    }
}

gl_update_SSBO :: inline (location: u32, size: s64, data: *void)
{
    assert(data != null);

    if size != 0
    {
        glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, location);
        glBufferSubData(GL_SHADER_STORAGE_BUFFER, 0, size, data);
        glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);
    }
    else
    {
        log("[WARNING]: We are skipping the updating of this GL_SSBO because it lacks data...\n");
    }
}

gl_update_UBO :: inline (location: u32, size: s64, data: *void)
{
    assert(data != null);
    assert(size != 0);

    glBindBufferBase(GL_UNIFORM_BUFFER, 0, location);
    glBufferSubData(GL_UNIFORM_BUFFER, 0, size, data);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
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

gl_shader_storage_buffer_object_update_buffer :: (shader: *GPU_Shader, buffer_name: string, size: s64, data: *void)
{
    shader_buffer: *GPU_Shader_Buffer;
    for *buffer: shader.SBO_buffer_data
    {
        if compare_strings(buffer_name, buffer.buffer_name) == 0
        {
            shader_buffer = buffer;
            break;
        }
    }
    if shader_buffer
    {
        if shader_buffer.read_only return;
        
        shader_buffer.buffer_data   = data;
        shader_buffer.buffer_size   = size;
        shader_buffer.update_buffer = gl_update_SSBO;
    }
    else
    {
        log_error("Invalid shader buffer name... name is: %...\n", buffer_name);
        assert(false);
    }
}

gl_shader_UBO_update_buffer :: (shader: *GPU_Shader, buffer_name: string, data: *void)
{
    shader_buffer: *GPU_Shader_Buffer;
    for *buffer: shader.UBO_buffer_data
    {
        if compare_strings(buffer_name, buffer.buffer_name) == 0
        {
            shader_buffer = buffer;
            break;
        }
    }

    if shader_buffer
    {
        shader_buffer.buffer_data   = data;
        shader_buffer.update_buffer = gl_update_UBO;
    }
    else
    {
        log_error("Invalid shader buffer name... name is: %...\n", buffer_name);
        assert(false);
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
            break;
        }
    }

    if shader_uniform
    {
        assert(shader_uniform.update_uniform != null);
        assert(data != null);

        shader_uniform.uniform_data = data;
    }
    else
    {
        log_error("Invalid shader uniform name... name is: %...\n", uniform_name);
        assert(false);
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
        log_error("\n[SHADER COMP ERROR]: %\n\n", to_string(log_data.data));

        return 0;
    }
    
    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);
    
    return program;
}

compile_compute_shader :: (arena: *Memory_Arena, shader_text: *string) -> GLuint
{
    LOG_BUFFER_SIZE :: 512;
    PREFIX_COMP :: #string END
        #version 430 core
    END

    compute_shader := make_shader_object(shader_text, PREFIX_COMP, GL_COMPUTE_SHADER);
    program        := glCreateProgram();

    glAttachShader(program, compute_shader);
    glLinkProgram(program);
    
    success: GLint = 0;
    glGetProgramiv(program, GL_LINK_STATUS, *success);
    if !success
    {
        log_data: [LOG_BUFFER_SIZE]u8;
        glGetProgramInfoLog(program, log_data.count, null, log_data.data);
        log_error("\n[SHADER COMP ERROR]: %\n\n", to_string(log_data.data));

        return 0;
    }

    glDeleteShader(compute_shader);
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
        };
    };
}

compile_shader_source :: (arena         : *Memory_Arena,
                          source        : *string,
                          buffer_configs: []GPU_Shader_Buffer_Config,
                          type          : GPU_Shader_Type) -> GPU_Shader
{
    shader: GPU_Shader;
    shader.shader_type       = type;
    shader.shader_source     = source.*;
    shader.SBO_buffer_config = buffer_configs;
    if shader.shader_type ==
    {
        case .PIXEL;
        {
            shader.program_id = compile_pixel_shader(arena, *shader.shader_source);
        }
        case .COMPUTE;
        {
            shader.program_id = compile_compute_shader(arena, *shader.shader_source);
        }
        case .UNDEFINED;
        {
            log_error("invalid code path\n\ncompile_shader_source();");
            assert(false);
        }
    }

    if shader.program_id != 0
    {
        // SHADER UNIFORM BUFFER OBJECTS
        {
            shader_UBO_count: s32;
            glGetProgramiv(shader.program_id, GL_ACTIVE_UNIFORM_BLOCKS, *shader_UBO_count);
            if shader_UBO_count > 0
            {
                shader.UBO_buffer_data = c_arena_push_array(arena, GPU_Shader_Buffer, xx shader_UBO_count);
                for UBO_index: 0..shader.UBO_buffer_data.count - 1
                {
                    UBO_data := *shader.UBO_buffer_data[UBO_index];

                    glGetActiveUniformBlockiv(shader.program_id, xx UBO_index, GL_UNIFORM_BLOCK_NAME_LENGTH, cast(*s32)*UBO_data.buffer_name.count);
                    UBO_data.buffer_name.count -= 1;
                    UBO_data.buffer_name.data   = c_arena_push_size(arena, size_of(u8) * xx(UBO_data.buffer_name.count + 1));
                    glGetActiveUniformBlockName(shader.program_id, xx UBO_index, xx(UBO_data.buffer_name.count + 1), null, UBO_data.buffer_name.data);

                    glGetActiveUniformBlockiv(shader.program_id, xx UBO_index, GL_UNIFORM_BLOCK_DATA_SIZE, cast(*s32)*UBO_data.buffer_size);
                    glGetActiveUniformBlockiv(shader.program_id, xx UBO_index, GL_UNIFORM_BLOCK_BINDING,   cast(*s32)*UBO_data.buffer_binding);

                    glGenBuffers(1, *UBO_data.location_id);
                    glBindBuffer(GL_UNIFORM_BUFFER, UBO_data.location_id);
                    glBufferData(GL_UNIFORM_BUFFER, UBO_data.buffer_size, null, GL_DYNAMIC_DRAW);
                    glBindBuffer(GL_UNIFORM_BUFFER, 0);
                }
            }
        }
        
        // SHADER UNIFORMS
        {
            shader_uniform_count: s32;
            glGetProgramiv(shader.program_id, GL_ACTIVE_UNIFORMS, *shader_uniform_count);
            if shader_uniform_count > 0
            {
                shader.uniform_data = c_arena_push_array(arena, GPU_Shader_Uniform, xx shader_uniform_count);
                true_uniform_index: s32;
                for uniform_index: 0..shader.uniform_data.count - 1
                {
                    uniform := *shader.uniform_data[true_uniform_index];
                    
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
                    if uniform.location_id != -1
                    {
                        true_uniform_index += 1;
                    }
                    else
                    {
                        log("[INFO]: Skipping uniform '%' as it is a member of a UBO...\n", uniform.uniform_name);
                        uniform.* = .{};
                    }
                }
            }
        }

        // SHADER STORAGE BUFFERS
        {
            shader_storage_buffer_count: s32;
            glGetProgramInterfaceiv(shader.program_id,
                                    GL_SHADER_STORAGE_BLOCK,
                                    GL_ACTIVE_RESOURCES,
                                   *shader_storage_buffer_count);
            if shader_storage_buffer_count != 0
            {
                shader.SBO_buffer_data = c_arena_push_array(arena, GPU_Shader_Buffer, xx shader_storage_buffer_count);
                for gpu_buffer_index: 0..shader.SBO_buffer_data.count - 1
                {
                    current_buffer := *shader.SBO_buffer_data[gpu_buffer_index];
                    buffer: [256]u8;
                    length: u32;
                    glGetProgramResourceName(shader.program_id,
                                             GL_SHADER_STORAGE_BLOCK,
                                             xx gpu_buffer_index,
                                             256,
                                            *length, buffer.data);
                    current_buffer.buffer_name.data  = c_arena_push_size(arena, size_of(u8) * length);
                    current_buffer.buffer_name.count = length;
                    memcpy(current_buffer.buffer_name.data, buffer.data, size_of(u8) * length);

                    shader_buffer_binding: s32;
                    property: GLenum = GL_BUFFER_BINDING;
                    glGetProgramResourceiv(shader.program_id,
                                           GL_SHADER_STORAGE_BLOCK,
                                           xx gpu_buffer_index,
                                           1,
                                          *property,
                                           1,
                                           null,
                                          *shader_buffer_binding);
                    current_buffer.buffer_binding = xx shader_buffer_binding;
                    assert(shader.SBO_buffer_config.data != null);
                    correct_buffer_config: *GPU_Shader_Buffer_Config;
                    for *buffer_config: shader.SBO_buffer_config
                    {
                        if compare_strings(current_buffer.buffer_name, buffer_config.buffer_name) == 0
                        {
                            correct_buffer_config = buffer_config;
                        }
                    }
                    assert(correct_buffer_config != null);
                    current_buffer.read_only = correct_buffer_config.read_only;

                    glGenBuffers(1, *current_buffer.location_id);
                    glBindBuffer(GL_SHADER_STORAGE_BUFFER, current_buffer.location_id);
                    glBufferData(GL_SHADER_STORAGE_BUFFER, correct_buffer_config.size_init, null, GL_DYNAMIC_DRAW);
                    glBindBuffer(GL_SHADER_STORAGE_BUFFER, 0);
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

        texture.is_gpu_tex = true;
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

r_init_renderer_data :: (window: *SDL_Window, asset_manager: *Asset_Manager) -> Render_State
{
    // NOTE(Sleepster): GL State Init 
    {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_FRAMEBUFFER_SRGB_CAPABLE, 1);
        // SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
        // SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
        
        gl_context := SDL_GL_CreateContext(window);
        SDL_GL_MakeCurrent(window, gl_context);
        gl_load(*gl, SDL_GL_GetProcAddress);
        gl_enable_debug_output();

        // glEnable(GL_DEPTH_TEST);
        // glDepthFunc(GL_GREATER);

        // glEnable(GL_STENCIL_TEST);
        // glStencilMask(0xFF);

        glEnable(GL_BLEND);        
        glBlendEquation(GL_FUNC_ADD);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_COLOR);

        // glBlendFuncSeparate(GL_ONE, GL_ONE, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
        // glBlendEquationSeparate(GL_MAX, GL_FUNC_ADD);

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
            glBufferData(GL_ARRAY_BUFFER, size_of(Vertex) * MAX_GROUP_VERTICES, null, GL_STREAM_DRAW);

            glGenBuffers(1, *primary_ebo_id);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, primary_ebo_id);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * MAX_QUAD_INDICES, quad_index_buffer.data, GL_STATIC_DRAW);

            T :: Vertex;
            offset: *T: null;
            glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, size_of(Vertex), xx *offset.vPosition);
            glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, size_of(Vertex), xx *offset.vColor);
            glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), xx *offset.vVSNormals);
            glVertexAttribPointer(3, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), xx *offset.vTexelData);

            glVertexAttribIPointer(4, 1, GL_UNSIGNED_INT, size_of(Vertex), xx *offset.vRenderOptions);
            glVertexAttribIPointer(5, 1, GL_UNSIGNED_INT, size_of(Vertex), xx *offset.vTextureIndex);
            glVertexAttribIPointer(6, 1, GL_UNSIGNED_INT, size_of(Vertex), xx *offset.vRenderLayer);
            
            glEnableVertexAttribArray(0);
            glEnableVertexAttribArray(1);
            glEnableVertexAttribArray(2);
            glEnableVertexAttribArray(3);
            glEnableVertexAttribArray(4);
            glEnableVertexAttribArray(5);
            glEnableVertexAttribArray(6);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        }
    }

    render_state.shadow_pass_shader = asset_get_shader(asset_manager, "c_shadow_map_shader");
    render_state.lightmap_shader    = asset_get_shader(asset_manager, "c_lightmap_shader");
    render_state.composite_shader   = asset_get_shader(asset_manager, "c_composite_shader");

    r_default_render_material = asset_get_render_material(asset_manager, "Default_Material");

    render_state.occluder2D_quad_buffer    = c_arena_push_array(*render_state.render_data_arena, Occluder2D, MAX_OCCLUDERS);
    render_state.occluder2D_vertex_buffer  = c_arena_push_array(*render_state.render_data_arena, Vertex,     MAX_OCCLUDERS * 4);

    render_state.lightmap_quad_buffer      = c_arena_push_array(*render_state.render_data_arena, Render_Quad, MAX_LIGHTS);
    render_state.lightmap_vertex_buffer    = c_arena_push_array(*render_state.render_data_arena, Vertex,      MAX_LIGHTS * 4);

    render_state.shader_point_light_buffer = c_arena_push_array(*render_state.render_data_arena, Shader_Light_Data, MAX_LIGHTS);
    render_state.engine_point_light_buffer = c_arena_push_array(*render_state.render_data_arena, Point_Light, MAX_LIGHTS);

    render_state.update_buffer     = gl_shader_storage_buffer_object_update_buffer;
    render_state.resize_shader_buf = gl_resize_SSBO;
    render_state.update_uniform    = gl_shader_update_uniform;
    render_state.update_UBO        = gl_shader_UBO_update_buffer;

    return render_state;
}

r_update_shader_data :: (working_group: *Render_Group, shader: *GPU_Shader, update_textures: bool = true)
{
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
            if working_group != null
            {
                if working_group.group_texture_count > 0 && update_textures
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
                        assert(uniform.type == .TEXTURE_ARRAY);
                        log("[ERROR]: Support for GPU_Shader texture arrays is not implemented...\n");

                        assert(false);
                    }
                }
            }
        }
    }

    for ubo_index: 0..shader.UBO_buffer_data.count - 1
    {
        UBO_data := *shader.UBO_buffer_data[ubo_index];
        assert(UBO_data.buffer_binding != -1);
        assert(UBO_data.update_buffer  != null);
        UBO_data.update_buffer(UBO_data.location_id,
                               UBO_data.buffer_size,
                               UBO_data.buffer_data);
    }

    for buffer_index: 0..shader.SBO_buffer_data.count - 1
    {
        shader_buffer := *shader.SBO_buffer_data[buffer_index];
        assert(shader_buffer.buffer_binding != -1);
        if !shader_buffer.read_only
        {
            assert(shader_buffer.update_buffer  != null);
            shader_buffer.update_buffer(shader_buffer.location_id,
                                        shader_buffer.buffer_size,
                                        shader_buffer.buffer_data);
        }
    }
}

DEBUG_draw_test_sprites :: (render_state: *Render_State, asset_manager: *Asset_Manager)
{
    render_state.draw_frame.active_render_material = r_default_render_material;

    render_state.draw_frame.active_shader            = asset_get_shader(asset_manager, "Basic_Shader");
    render_state.draw_frame.active_view_matrix       = mat4_identity();
    render_state.draw_frame.active_projection_matrix = orthographic_projection_matrix(global_window_data.current_window_size.x * -0.5,
                                                                                      global_window_data.current_window_size.x *  0.5,
                                                                                      global_window_data.current_window_size.y * -0.5,
                                                                                      global_window_data.current_window_size.y *  0.5,
                                                                                     -1.0,
                                                                                      1.0);
    r_push_render_layer(render_state, 17);
    r_draw_quad(render_state,   .{-1000, -500}, .{1920, 1080}, .{0, 0, 0, 1});
    r_push_render_layer(render_state, 16);

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

    r_draw_sprite(render_state, .{-200,  150}, .{100, 100}, .{1, 0, 0, 1},   sprite, deg_to_rad(140));
    r_draw_quad(render_state,   .{ 200,  150}, .{100, 100}, .{0, 1, 0, 1},   texture.texID, 0);
    r_draw_quad(render_state,   .{ 200, -150}, .{100, 100}, .{0, 0, 1, 1},   texture.texID, 0);
    r_draw_quad(render_state,   .{-200, -150}, .{100, 100}, .{1, 0, 1, 1},   texture.texID, .RO_OCCLUDER, deg_to_rad(33));
    r_draw_quad(render_state,   .{-200, -125}, .{ 50,  50}, .{1, 0, 0, 0.8});
    r_draw_quad(render_state,   .{-175, -125}, .{ 50,  50}, .{0, 0, 1, 0.8});

    font := asset_get_font(asset_manager, "LiberationMono-Regular");
    r_draw_text(render_state, font, "Let's go crazy with it.", .{-250, 0}, 64, .{1, 1, 1, 1});

    // for 0..10000
    // {
    //     r_draw_quad(render_state,   .{-1750, -125}, .{ 50,  50}, .{0, 0, 1, 0.8});
    // }

    // for 0..10000
    // {
    //     r_draw_quad(render_state,   .{-200, -150}, .{100, 100}, .{1, 0, 1, 1},   texture.texID, .RO_NONE, deg_to_rad(33));
    // }

    light  := r_create_point_light(render_state, .{ 500, 100}, .{0.30, 0.30, 0.30, 1.0}, .{ 0, 1},  deg_to_rad(45), 500, 1.0);
    default_material := asset_get_render_material(asset_manager, "Default_Material");
    
    // NOTE(Sleepster): This would be done by the game programmer
    // during their game update. This information is a form of
    // deferred updating, simply REGISTERING the data. At render
    // time, and no earlier, this data is sent to the GPU.
    render_state.update_uniform(render_state.draw_frame.active_shader,
                               "uProjectionMatrix",
                               *render_state.draw_frame.active_projection_matrix._11);
    render_state.update_uniform(render_state.draw_frame.active_shader,
                              "uViewMatrix",
                              *render_state.draw_frame.active_view_matrix._11);
    render_state.update_uniform(render_state.draw_frame.active_shader,
                              "uPointLightCount",
                              *render_state.draw_frame.light_count);
    render_state.update_uniform(render_state.draw_frame.active_shader,
                               "uAmbientLighting",
                               *ambient_factor);
    render_state.update_buffer(render_state.draw_frame.active_shader,
                              "PointLightSBO",
                               size_of(Shader_Light_Data) * render_state.draw_frame.light_count,
                               render_state.shader_point_light_buffer.data);
    render_state.update_UBO(render_state.draw_frame.active_shader,
                           "uMaterial",
                           *default_material);
    // for 0..100
    // {
    //     light3 := r_create_point_light(render_state, .{-250, 0}, .{0.70, 0.30,  0.30, 1.0}, .{1, 0}, deg_to_rad(180), 500, 1.0);
    // }
    
}

DEBUG_draw_test_sprites_experimental :: (render_state: *Render_State, asset_manager: *Asset_Manager)
{
    render_state.draw_frame.active_render_material    = r_default_render_material;

    render_state.draw_frame.active_shader             = asset_get_shader(asset_manager, "Basic_Shader");
    render_state.draw_frame.active_view_matrix        = mat4_identity();
    render_state.draw_frame.active_projection_matrix  = orthographic_projection_matrix(320 * -0.5,
                                                                                       320 *  0.5,
                                                                                       180 * -0.5,
                                                                                       180 *  0.5,
                                                                                       -1.0,
                                                                                       1.0);
    r_push_render_layer(render_state, 17);
    r_draw_quad(render_state, .{-300,-160}, .{640, 360}, .{0.01, 0.01, 0.01, 1});
    r_push_render_layer(render_state, 16);

    r_draw_quad(render_state, .{ 60, -60}, .{8, 96},  .{1, 0, 0, 1}, U32_MAX, .RO_OCCLUDER);
    r_draw_quad(render_state, .{-60,   0}, .{16, 16}, .{1, 0, 0, 1}, U32_MAX, .RO_OCCLUDER, deg_to_rad(45));
    r_draw_quad(render_state, .{  0,  60}, .{16, 16}, .{1, 0, 0, 1}, U32_MAX, .RO_OCCLUDER);

    sprite  := asset_get_sprite(asset_manager,  "player");
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

    for 0..400
    {
        r_create_point_light(render_state, .{ 0,    0}, .{1.0, 1.0,  1.0, 1.0}, .{1, 1}, deg_to_rad(180), 100, 2.0);
    }
    // r_create_point_light(render_state, .{ 60,   0}, .{1.0, 1.0,  1.0, 1.0}, .{1, 1}, deg_to_rad(180), 100, 2.0);
    // r_create_point_light(render_state, .{-60, -20}, .{1.0, 1.0,  1.0, 1.0}, .{1, 1}, deg_to_rad(180), 100, 2.0);
    // r_create_point_light(render_state, .{ 80,   0}, .{1.0, 1.0,  1.0, 1.0}, .{1, 1}, deg_to_rad(180), 100, 2.0);

    // r_create_point_light(render_state, .{  0,  60}, .{1.0, 1.0,  1.0, 1.0}, .{1, 1}, deg_to_rad(180), 100, 2.0);

    default_material := asset_get_render_material(asset_manager, "Default_Material");
    
    // NOTE(Sleepster): This would be done by the game programmer
    // during their game update. This information is a form of
    // deferred updating, simply REGISTERING the data. At render
    // time, and no earlier, this data is sent to the GPU.
    render_state.update_uniform(render_state.draw_frame.active_shader,
                               "uProjectionMatrix",
                               *render_state.draw_frame.active_projection_matrix._11);
    render_state.update_uniform(render_state.draw_frame.active_shader,
                              "uViewMatrix",
                              *render_state.draw_frame.active_view_matrix._11);
    render_state.update_uniform(render_state.draw_frame.active_shader,
                              "uPointLightCount",
                              *render_state.draw_frame.light_count);
    render_state.update_uniform(render_state.draw_frame.active_shader,
                               "uAmbientLighting",
                               *ambient_factor);
    render_state.update_buffer(render_state.draw_frame.active_shader,
                              "PointLightSBO",
                               size_of(Shader_Light_Data) * render_state.draw_frame.light_count,
                               render_state.shader_point_light_buffer.data);
    render_state.update_UBO(render_state.draw_frame.active_shader,
                           "uMaterial",
                           *default_material);
}

is_quad_within_light_radius :: inline (light: *Point_Light, working_quad: *Render_Quad) -> bool
{
    result: bool;

    result = (square(working_quad.center_pos.x - light.ws_position.x) +
              square(working_quad.center_pos.y - light.ws_position.y)) <= square(light.light_data.radius);

    return result;
}

r_render_group_test_render :: (render_state: *Render_State, asset_manager: *Asset_Manager)
{
    glViewport(0, 0, xx global_window_data.current_window_size.x, xx global_window_data.current_window_size.y);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClearDepth(0.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    glEnable(GL_DEPTH_TEST);

    glBindVertexArray(render_state.primary_vao_id);

    // NOTE(Sleepster): Primary Geometry Pass 
    r_handle_group_buffers(render_state);
    for group_index: 0..render_state.draw_frame.render_group_counter - 1
    {
        working_group := render_state.draw_frame.render_groups[group_index];
        shader := working_group.bound_shader;
        glUseProgram(shader.program_id);

        opaque_quad_count := working_group.current_quad_count - working_group.t_quad_count;
        glBindBuffer(GL_ARRAY_BUFFER, render_state.primary_vbo_id);
        glBufferSubData(GL_ARRAY_BUFFER,
                        0,
                        (working_group.vertex_count * size_of(Vertex)),
                        working_group.vertex_buffer.data);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, render_state.primary_ebo_id);
        r_update_shader_data(working_group, shader);
        if opaque_quad_count > 0
        {
            glDepthFunc(GL_GREATER);
            glDepthMask(GL_TRUE);
            glDrawElements(GL_TRIANGLES,
                           opaque_quad_count * 6,
                           GL_UNSIGNED_INT,
                           null);
        }
        if working_group.t_quad_count > 0
        {
            glDepthFunc(GL_GEQUAL);
            glDepthMask(GL_FALSE);
            glDrawElements(GL_TRIANGLES,
                           working_group.t_quad_count * 6,
                           GL_UNSIGNED_INT,
                           cast(*void)((opaque_quad_count * 6) * size_of(u32)));
        }
    }
}

framebuffer_id   : u32;
ffb_rgba_texture : u32;
ffb_depth_texture: u32;

s_framebuffer_id: u32;
sfb_lightmap    : u32;

#no_reset experimental_init: bool = false;
r_experimental_DEFERRED_rendering :: (render_state: *Render_State, asset_manager: *Asset_Manager)
{
    render_engine_width : u32 = 320;
    render_engine_height: u32 = 180;

    if !experimental_init
    {
        // NOTE(Sleepster): MAIN FRAMEBUFFER 
        {
            glGenFramebuffers(1, *framebuffer_id);
            glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_id);

            glGenTextures(1, *ffb_rgba_texture);
            glBindTexture(GL_TEXTURE_2D, ffb_rgba_texture);

            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);


            glTexImage2D(GL_TEXTURE_2D, 0, GL_SRGB8_ALPHA8, 
                         render_engine_width, render_engine_height, 0, 
                         GL_RGBA, GL_UNSIGNED_BYTE, null);

            glGenTextures(1, *ffb_depth_texture);
            glBindTexture(GL_TEXTURE_2D, ffb_depth_texture);

            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

            glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24, 
                         render_engine_width, render_engine_height, 0, 
                         GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, null);


            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, ffb_rgba_texture, 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,  GL_TEXTURE_2D, ffb_depth_texture, 0);
            draw_buffers: []GLenum = .[GL_COLOR_ATTACHMENT0];
            glDrawBuffers(1, draw_buffers.data);
        }

        // NOTE(Sleepster): LIGHTING FRAMEBUFFER
        {
            glGenFramebuffers(1, *s_framebuffer_id);
            glBindFramebuffer(GL_FRAMEBUFFER, s_framebuffer_id);

            glGenTextures(1, *sfb_lightmap);
            glBindTexture(GL_TEXTURE_2D, sfb_lightmap);

            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 
                         LIGHTMAP_SIZE, LIGHTMAP_SIZE, 0, 
                         GL_RGB, GL_FLOAT, null);


            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, sfb_lightmap, 0);
        }

        experimental_init = true;
    }
    glBindVertexArray(render_state.primary_vao_id);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, render_state.primary_ebo_id);

    r_handle_lighting_data(render_state);
    // NOTE(Sleepster): Shadow and lighting pass 
    {
        glBindFramebuffer(GL_FRAMEBUFFER, s_framebuffer_id);
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);

        glViewport(0, 0, LIGHTMAP_SIZE, LIGHTMAP_SIZE);

        /*
            TODO:
            Render the lighting using glDrawElementsInstanced for each light. (an Instance per light)
            Then cut out the shadows for the specific color mask.
        */

        atlas_proj_matrix := orthographic_projection_matrix(LIGHTMAP_SIZE * -0.5,
                                                            LIGHTMAP_SIZE *  0.5,
                                                            LIGHTMAP_SIZE * -0.5,
                                                            LIGHTMAP_SIZE *  0.5,
                                                            -1.0,
                                                            1.0);
        
        glEnable(GL_BLEND);        
        // NOTE(Sleepster): RENDER LIGHTS 
        {
            glBlendFunc(GL_ONE, GL_ONE);
            glBlendEquation(GL_FUNC_ADD);
            
            glBindBuffer(GL_ARRAY_BUFFER, render_state.primary_vbo_id);
            glBufferSubData(GL_ARRAY_BUFFER,
                            0,
                            render_state.draw_frame.lightmap_vertex_count * size_of(Vertex),
                            render_state.lightmap_vertex_buffer.data);

            glUseProgram(render_state.lightmap_shader.program_id);
            render_state.update_uniform(render_state.lightmap_shader,
                                       "uProjectionMatrix",
                                       *atlas_proj_matrix._11);
            render_state.update_buffer(render_state.lightmap_shader,
                                       "PointLightSBO",
                                       size_of(Shader_Light_Data) * render_state.draw_frame.light_count,
                                       render_state.shader_point_light_buffer.data);

            r_update_shader_data(null, render_state.lightmap_shader);
            
            glDrawElements(GL_TRIANGLES,
                           render_state.draw_frame.light_count * 6,
                           GL_UNSIGNED_INT,
                           null);
        }

        // NOTE(Sleepster): RENDER SHADOWS 
        {
            glBlendFunc(GL_ONE, GL_ONE);
            glBlendEquation(GL_FUNC_REVERSE_SUBTRACT);

            glBindBuffer(GL_ARRAY_BUFFER, render_state.primary_vbo_id);
            glBufferSubData(GL_ARRAY_BUFFER,
                            0,
                            render_state.draw_frame.occluder_vertex_count * size_of(Vertex),
                            render_state.occluder2D_vertex_buffer.data);

            glUseProgram(render_state.shadow_pass_shader.program_id);
            render_state.update_uniform(render_state.shadow_pass_shader,
                                       "uProjectionMatrix",
                                       *atlas_proj_matrix._11);

            r_update_shader_data(null, render_state.shadow_pass_shader);
            glDrawElements(GL_TRIANGLES,
                           (render_state.draw_frame.occluder_vertex_count / 4) * 6,
                           GL_UNSIGNED_INT,
                           null);
        }
    }

    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_id);

    glViewport(0, 0, render_engine_width, render_engine_height);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClearDepth(0.0);

    glEnable(GL_DEPTH_TEST);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glDepthFunc(GL_GREATER);
    glDepthMask(GL_TRUE);

    // NOTE(Sleepster): Primary Geometry Pass 
    r_handle_group_buffers(render_state);
    for group_index: 0..render_state.draw_frame.render_group_counter - 1
    {
        working_group := render_state.draw_frame.render_groups[group_index];
        shader := working_group.bound_shader;
        glUseProgram(shader.program_id);

        opaque_quad_count := working_group.current_quad_count - working_group.t_quad_count;
        glBindBuffer(GL_ARRAY_BUFFER, render_state.primary_vbo_id);
        glBufferSubData(GL_ARRAY_BUFFER,
                        0,
                        (working_group.vertex_count * size_of(Vertex)),
                        working_group.vertex_buffer.data);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, render_state.primary_ebo_id);
        r_update_shader_data(working_group, shader);
        if opaque_quad_count > 0
        {
            glDepthFunc(GL_GREATER);
            glDepthMask(GL_TRUE);
            glDrawElements(GL_TRIANGLES,
                           opaque_quad_count * 6,
                           GL_UNSIGNED_INT,
                           null);
        }
        if working_group.t_quad_count > 0
        {
            glDepthFunc(GL_GEQUAL);
            glDepthMask(GL_FALSE);
            glDrawElements(GL_TRIANGLES,
                           working_group.t_quad_count * 6,
                           GL_UNSIGNED_INT,
                           cast(*void)((opaque_quad_count * 6) * size_of(u32)));
        }
    }

    // NOTE(Sleepster): COMPOSITE RENDER 
    {
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glClearColor(0.00, 0.00, 0.00, 1.0);
    glClearDepth(0.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer_id);
    glBlitFramebuffer(0,
                      0,
                   xx render_engine_width,
                   xx render_engine_height,
                      0,
                      0,
                   xx global_window_data.current_window_size.x,
                   xx global_window_data.current_window_size.y,
                      GL_COLOR_BUFFER_BIT,
                      GL_NEAREST);
}

r_reset_draw_frame :: (render_state: *Render_State)
{
    c_arena_reset(*render_state.draw_frame_arena);
    render_state.draw_frame.light_count          = 0;
    render_state.draw_frame.current_render_layer = 32;
    render_state.draw_frame                      = .{};

    // TODO(Sleepster): ????
    previous_window_size := global_window_data.old_window_size;
    window_size          := global_window_data.current_window_size;
}
