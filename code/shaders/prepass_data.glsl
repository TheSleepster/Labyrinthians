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

uniform mat4 uProjectionMatrix;
uniform mat4 uViewMatrix;

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
layout(location = 1) out vec4 vOutShadowCaster;

void
main()
{
    if((vOutRenderOptions & RO_SHADOW_CASTER) != 0)
    {
        vOutShadowCaster = vec4(1.0);
    }
    else
    {
        vOutShadowCaster = vec4(0.0);
    }

    vec4 DiffuseColor = vec4(0);
    if((vOutRenderOptions & RO_TEXEL_FETCHED) != 0)
    {
        DiffuseColor = texelFetch(uNormalMap, ivec2(vOutTexelData), 0);
    }
    else
    {
        DiffuseColor = texture(uNormalMap, vOutTexelData);
    }

    vOutNormalColor = DiffuseColor + vec4(vOutVSNormals, 1.0);
}
#endif
