#define RO_NONE          0x00 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02
#define RO_OCCLUDER      0x04
struct point_light
{
    vec4                   Color;
    vec4                   LightAtlasColorMask;
    float                  padding_0[2];
    vec2                   LightAtlasUVs;
    vec2                   vsPosition;
    vec2                   csPosition;
    vec2                   Direction;
    float                  SpotAngle;
    float                  Radius;
    float                  Strength; 
    float                  padding_1[3];
};

#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec3 vVSNormals;
layout(location = 3) in vec2 vTexelData;
layout(location = 4) in uint vRenderingOptions;
layout(location = 5) in uint vTextureIndex;
layout(location = 6) in uint vRenderLayer;

layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

uniform mat4 uProjectionMatrix;

out flat uint InstanceID;
out      vec4 vColorMask;
out      vec4 vLightColor;
out      vec2 vLightAtlasUVs;

void
main()
{
    point_light Light = PointLights[vTextureIndex];

    vColorMask     = Light.LightAtlasColorMask;
    vLightColor    = Light.Color;
    vLightAtlasUVs = vTexelData;
    gl_Position    = uProjectionMatrix * vPosition;
}
#endif

#ifdef FRAGMENT_SHADER
layout(binding = 0) uniform sampler2D uShadowMap;

in      vec4 vColorMask;
in      vec4 vLightColor;
in      vec2 vLightAtlasUVs;
in flat uint InstanceID;

out vec4 vFragColor;

void
main()
{
    vec4 SampleValue  = texture(uShadowMap, vLightAtlasUVs) * vColorMask;
    vec4 Alpha        = vec4(SampleValue.r + SampleValue.g + SampleValue.b + SampleValue.a);

    vFragColor = vLightColor * Alpha;
}
#endif
