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
