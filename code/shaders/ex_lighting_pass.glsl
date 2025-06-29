#define RO_NONE          0 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02

struct point_light
{
    vec4                   Color;
    vec2                   vsPosition;
    vec2                   csPosition;
    vec2                   Direction;
    float                  SpotAngle;
    float                  Radius;
    float                  Strength; 
    float                  padding[3];
};

#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec3 vVSNormals;
layout(location = 3) in vec2 vTexelData;
layout(location = 4) in uint vRenderingOptions;
layout(location = 5) in uint vTextureIndex;

void
main()
{
    vec2 Vertices[6] = 
    {
        vec2(-1,  1), // Top-left
        vec2( 1,  1), // Top-right
        vec2(-1, -1), // Bottom-left
        vec2(-1, -1), // Bottom-left
        vec2( 1, -1), // Bottom-right
        vec2( 1,  1), // Top-right
    };

    gl_Position = vec4(Vertices[gl_VertexID], 0.0, 1.0);
}
#endif

#ifdef FRAGMENT_SHADER
layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};
uniform int  uPointLightCount;

out vec4 vFragColor;

void
main()
{
}

#endif
