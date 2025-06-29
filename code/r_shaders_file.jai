// TODO(Sleepster): Make a common header between all of the shaders
// that need it, then use the string builder to print out the full shader
// here at compile time

BASIC_SHADER_SOURCE_TEXT :: #run -> string
{
    return read_entire_file("shaders/basic_forward_shader.glsl");
};

LIGHT_CLUSTERING_COMPUTE_SHADER :: #run -> string
{
    return read_entire_file("shaders/forward_light_clustering.glsl");
};

SHADOW_MAP_SHADER :: #run -> string
{
    return read_entire_file("shaders/shadow_map_shader.glsl");
}

VERTEX_NORMALS_EXTRACTION_SHADER :: #run -> string
{
    return read_entire_file("shaders/vertex_normals_extraction_shader.glsl");
}

OCCLUSION_RENDERER_SHADER :: #run -> string
{
    return read_entire_file("shaders/occlusion_object_shader.glsl");
}

EX_FORWARD_SHADER :: #run -> string
{
    return read_entire_file("shaders/ex_forward_shader.glsl");
}
