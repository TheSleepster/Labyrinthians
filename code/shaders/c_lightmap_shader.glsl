#define RO_NONE          0x00 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02
#define RO_OCCLUDER      0x04
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
layout(location = 6) in uint vRenderLayer;

uniform mat4 uProjectionMatrix;

out vec4 vColorMask;
out vec2 vAtlasUVs;

void
main()
{
    vColorMask  = vColor;
    vAtlasUVs   = vTexelData;
    gl_Position = uProjectionMatrix * vPosition;
}
#endif

#ifdef FRAGMENT_SHADER
layout(binding = 0) uniform sampler2D uShadowMap;

in vec4 vColorMask;
in vec2 vAtlasUVs;

out vec4 vFragColor;

void
main()
{
    vec4 TextureColor = texture(uShadowMap, vAtlasUVs, 0) * vColorMask; 
    float Alpha       = TextureColor.r + TextureColor.g + TextureColor.b + TextureColor.a;

    vFragColor = vec4(vColorMask.rgb, Alpha);
}
#endif
