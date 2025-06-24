#define RO_NONE          0 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02
#define RO_SHADOW_CASTER 0x10

#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec3 vVSNormals;
layout(location = 3) in vec2 vTexelData;
layout(location = 4) in uint vRenderingOptions;
layout(location = 5) in uint vTextureIndex;

layout(location = 0) uniform mat4 uViewMatrix;
layout(location = 1) uniform mat4 uProjectionMatrix;

layout(location = 0)      out vec2 vOutTexelData;
layout(location = 1)      out vec3 vOutVSNormals;
layout(location = 2) flat out uint vOutRenderOptions;

void
main()
{
    vOutTexelData     = vTexelData;
    vOutVSNormals     = vVSNormals;
    vOutRenderOptions = vRenderingOptions;

    gl_Position       = uProjectionMatrix * uViewMatrix * vPosition;
}
#endif

#ifdef FRAGMENT_SHADER

uniform sampler2D uNormalMap;

layout(location = 0)      in vec2 vOutTexelData;
layout(location = 1)      in vec3 vOutVSNormals;
layout(location = 2) flat in uint vOutRenderOptions;

layout(location = 0) out vec4 vOutNormalColor;

void
main()
{
    vec4 SampledNormals = vec4(0);
    if((vOutRenderOptions & RO_TEXEL_FETCHED) != 0)
    {
        SampledNormals = texelFetch(uNormalMap, ivec2(vOutTexelData), 0);
    }
    else
    {
        SampledNormals = texture(uNormalMap, vOutTexelData);
    }

    SampledNormals  = SampledNormals == vec4(0.0) ? SampledNormals : vec4(vOutVSNormals, 1.0);
    vOutNormalColor = SampledNormals;
}
#endif
