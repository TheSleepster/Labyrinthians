#define RO_NONE          0x00 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02
#define RO_OCCLUDER      0x04

#ifdef VERTEX_SHADER
out vec2 vOutTexelData;

void
main()
{
    vec2 csPosition[6] = 
    {
        vec2(-1,  1), // Top-left
        vec2( 1,  1), // Top-right
        vec2(-1, -1), // Bottom-left
        vec2(-1, -1), // Bottom-left
        vec2( 1, -1), // Bottom-right
        vec2( 1,  1), // Top-right
    };

    vec2 UVData[6] = 
    {
        vec2(0.0, 1.0), 
        vec2(1.0, 1.0), 
        vec2(0.0, 0.0), 
        vec2(0.0, 0.0), 
        vec2(1.0, 0.0), 
        vec2(1.0, 1.0), 
    };

    vOutTexelData = UVData[gl_VertexID];
    gl_Position   = vec4(csPosition[gl_VertexID], 0.0, 1.0);
}
#endif

#ifdef FRAGMENT_SHADER
layout(binding = 0) uniform sampler2D uDiffuseTexture;
layout(binding = 1) uniform sampler2D uNormalTexture;
layout(binding = 2) uniform sampler2D uLightMap;
layout(binding = 3) uniform sampler2D uPositionTexture;

in vec2 vOutTexelData;

out vec4 vFragColor;

void
main()
{
    const float AmbientLight = 0.1;
    
    vec4 DiffuseColor = texture(uDiffuseTexture,  vOutTexelData);
    vec4 NormalsColor = texture(uNormalTexture,   vOutTexelData);
    vec4 LightColor   = texture(uLightMap,        vOutTexelData);
    vec4 PositionData = texture(uPositionTexture, vOutTexelData);

    uint RenderOptions = uint(PositionData.w);
    if((RenderOptions & RO_UNLIT) != 0)
    {
        vFragColor = DiffuseColor;
        return;
    }

    vec3 TrueColor = DiffuseColor.rgb * vec3(AmbientLight + (LightColor.rgb * vec3(0.5)));
    vFragColor = vec4(TrueColor, 1.0);
}
#endif
