#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec3 vVSNormals;
layout(location = 3) in vec2 vTexelData;
layout(location = 4) in uint vRenderingOptions;
layout(location = 5) in uint vTextureIndex;
layout(location = 6) in uint vRenderLayer;

uniform mat4 uProjectionMatrix;
uniform mat4 uViewMatrix;

out vec4 vColorMask;
out vec2 vAtlasUVs;

void
main()
{
    vColorMask  = vColor;
    vAtlasUVs   = vTexelData;
    gl_Position = uProjectionMatrix * uViewMatrix * vPosition;
}

#endif

#ifdef FRAGMENT_SHADER

in vec4 vColorMask;
in vec2 vAtlasUVs;

out vec4 vFragColor;

void
main()
{
    vFragColor = vColorMask;
}

#endif
