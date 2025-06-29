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

layout(location = 0) flat out uint vOutRenderOptions;

void
main()
{
    vOutRenderOptions = vRenderingOptions;

    gl_Position       = uProjectionMatrix * uViewMatrix * vPosition;
}

#endif

#ifdef FRAGMENT_SHADER
layout(location = 0) flat in  uint vOutRenderOptions;
layout(location = 0)      out vec4 vOutShadowCaster;

void
main()
{
    if((vOutRenderOptions & RO_SHADOW_CASTER) != 0)
    {
        vOutShadowCaster = vec4(1.0);
    }
    else
    {
        discard;
    }
}
#endif
