/*
  TODO:
  what outputs are needed?
     - Diffuse buffer
     - Normals buffer (if the vertex is not sourced from a normal map)
     - Position buffer
     - render_layer (with positions)
     - render_options
*/

#define RO_NONE          0x00 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x10
#define RO_OCCLUDER      0x10
#define RO_NORMAL_MAPPED 0x11

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

layout(location = 0)      out vec4 vOutColor;
layout(location = 1)      out vec4 vOutgBufferPos;
layout(location = 2)      out vec3 vOutNormals;
layout(location = 3)      out vec2 vOutTexelData;
layout(location = 4) flat out uint vOutRenderingOptions;
layout(location = 5) flat out uint vOutTexIndex;
layout(location = 6) flat out uint vOutRenderLayer;

void
main()
{
    vec4 csPosition = uProjectionMatrix * uViewMatrix * vPosition;

    vOutColor            = vColor;
    vOutNormals          = vVSNormals;
    vOutgBufferPos       = csPosition; 
    vOutTexelData        = vTexelData;
    vOutRenderingOptions = vRenderingOptions;
    vOutTexIndex         = vTextureIndex;
    vOutRenderLayer      = vRenderLayer;

    gl_Position = csPosition;
}
#endif

#ifdef FRAGMENT_SHADER

layout(location = 0)      in vec4 vOutColor;
layout(location = 1)      in vec4 vOutgBufferPos;
layout(location = 2)      in vec3 vOutNormals;
layout(location = 3)      in vec2 vOutTexelData;
layout(location = 4) flat in uint vOutRenderingOptions;
layout(location = 5) flat in uint vOutTexIndex;
layout(location = 6) flat in uint vOutRenderLayer;

layout(location = 0) out vec4 vOutDiffuseColor;
layout(location = 1) out vec3 vOutNormalsColor;
layout(location = 2) out vec4 vOutPositionColor;

uniform sampler2D uAtlasArray[16];

void
main()
{
    if(vOutTexIndex > 0)
    {
        if((vOutRenderingOptions & RO_TEXEL_FETCHED) != 0)
        {
            vOutDiffuseColor = texelFetch(uAtlasArray[vOutTexIndex], ivec2(vOutTexelData), 0);
        }
        else
        {
            vOutDiffuseColor = texture(uAtlasArray[vOutTexIndex], vOutTexelData);
        }

        if(vOutDiffuseColor.a == 0.0) discard;
    }
    else
    {
        vOutDiffuseColor = vOutColor;
    }

    // NOTE(Sleepster): Does not source from a normal texture 
    if((vOutRenderingOptions & RO_NORMAL_MAPPED) == 0)
    {
        vOutNormalsColor = vOutNormals;
    }
    else
    {
        vOutNormalsColor = vec3(0.0);
    }

    vec2 gBufferExtraData = vec2(float(vOutRenderLayer), float(vOutRenderingOptions));
    vOutPositionColor = vec4(vOutgBufferPos.xy, gBufferExtraData);
}

#endif
