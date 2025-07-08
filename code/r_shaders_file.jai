// TODO(Sleepster): Make a common header between all of the shaders
// that need it, then use the string builder to print out the full shader
// here at compile time

BASIC_SHADER_SOURCE_TEXT :: #run -> string
{
    return read_entire_file("shaders/basic_forward_shader.glsl");
};

c_SHADOWMAP_SHADER_TEXT :: #run -> string
{
    return read_entire_file("shaders/c_shadowmap_shader.glsl");
}
