// TODO(Sleepster): Make a common header between all of the shaders
// that need it, then use the string builder to print out the full shader
// here at compile time

BASIC_SHADER_SOURCE_TEXT :: #run -> string
{
    return read_entire_file("shaders/basic_forward_shader.glsl");
};

LIGHTMAP_SHADER_TEXT :: #run -> string
{
    return read_entire_file("shaders/lightmap_shader.glsl");
};

LIGHT_CLUSTERING_COMPUTE_SHADER :: #run -> string
{
    return read_entire_file("shaders/forward_light_clustering.glsl");
};

FINAL_STAGE_MIXING_SHADER :: #run -> string
{
    return read_entire_file("a_asset.jai");
};
