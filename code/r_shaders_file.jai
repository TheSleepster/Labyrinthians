BASIC_SHADER_SOURCE_TEXT :: #string END
#define RO_NONE          0 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02

#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec2 vTexelData;
layout(location = 3) in uint vRenderingOptions;
layout(location = 4) in uint vTextureIndex;

uniform mat4 ProjectionMatrix;
uniform mat4 ViewMatrix;

     out vec4 vOutColor; 
     out vec2 vOutTexelData;
flat out uint vOutRenderingOptions;
flat out uint vOutTexIndex;

void
main()
{
    vOutColor            = vColor;
    vOutTexelData        = vTexelData;
    vOutRenderingOptions = vRenderingOptions;
    vOutTexIndex         = vTextureIndex;

    gl_Position          = ProjectionMatrix * ViewMatrix * vPosition;
}
#endif

#ifdef FRAGMENT_SHADER
layout(location = 0)      in vec4 vOutColor;
layout(location = 1)      in vec2 vOutTexelData;
layout(location = 2) flat in uint vOutRenderingOptions;
layout(location = 3) flat in uint vOutTexIndex;

out vec4 vFragColor;

uniform sampler2D AtlasArray[16];

void
main()
{
    vec4 TextureColor;
    if(vOutTexIndex > 0)
    {
        if((vOutRenderingOptions & RO_TEXEL_FETCHED) != 0)
        {
            TextureColor = texelFetch(AtlasArray[vOutTexIndex], ivec2(vOutTexelData), 0);
        }
        else
        {
            TextureColor = texture(AtlasArray[vOutTexIndex], vOutTexelData);
        }
        
        if(TextureColor.a == 0.0)
        {
            discard;
        }
    }
    else
    {
        TextureColor = vOutColor;
    }
    vFragColor = TextureColor * vOutColor;
}
#endif
END
