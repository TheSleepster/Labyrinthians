#define RO_NONE          0 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02

#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec3 vVSNormals;
layout(location = 3) in vec2 vTexelData;
layout(location = 4) in uint vRenderingOptions;
layout(location = 5) in uint vTextureIndex;

uniform mat4 uProjectionMatrix;
uniform mat4 uViewMatrix;

layout(location = 0) out vec4 vOutFragPos;

void
main()
{
    gl_Position = uProjectionMatrix * uViewMatrix * vPosition;
}

#endif

#ifdef FRAGMENT_SHADER

out vec4 vFragColor;

void
main()
{
    vFragColor = vec4(vec3(0.0), 1.0);
}
#endif
