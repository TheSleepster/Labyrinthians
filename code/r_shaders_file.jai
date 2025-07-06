// TODO(Sleepster): Make a common header between all of the shaders
// that need it, then use the string builder to print out the full shader
// here at compile time

BASIC_SHADER_SOURCE_TEXT :: #run -> string
{
    return read_entire_file("shaders/basic_forward_shader.glsl");
};

EX_GBUFFER_SHADER_TEXT :: #run -> string
{
    return read_entire_file("shaders/ex_gbuffer_shader.glsl");
};

EX_SHADOW_SHADER_TEXT :: #run -> string
{
    return read_entire_file("shaders/ex_shadow_map_shader.glsl");
}

EX_LIGHT_MAP_SHADER_TEXT :: #run -> string
{
    return read_entire_file("shaders/ex_light_map_shader.glsl");
}

EX_COMPOSITION_SHADER_TEXT :: #run -> string
{
    return read_entire_file("shaders/ex_composition_shader.glsl");
}
