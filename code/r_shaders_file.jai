BASIC_SHADER_SOURCE_TEXT :: #string END
#define RO_NONE          0 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02

#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec2 vTexelData;
layout(location = 3) in uint vRenderingOptions;

uniform mat4 ProjectionMatrix;
uniform mat4 ViewMatrix;

     out vec4 vOutColor; 
     out vec2 vOutTexelData;
flat out uint vOutRenderingOptions;

void
main()
{
    vOutColor            = vColor;
    vOutTexelData        = vTexelData;
    vOutRenderingOptions = vRenderingOptions;

    gl_Position          = ProjectionMatrix * ViewMatrix * vPosition;
}
#endif

#ifdef FRAGMENT_SHADER
layout(location = 0)      in vec4 vOutColor;
layout(location = 1)      in vec2 vOutTexelData;
layout(location = 2) flat in uint vOutRenderingOptions;

out vec4 vFragColor;

layout(binding = 0) uniform sampler2D TestTexture;

void
main()
{
    vec4 TextureColor;
    if((vOutRenderingOptions & RO_TEXEL_FETCHED) != 0)
    {
        TextureColor = texelFetch(TestTexture, ivec2(vOutTexelData), 0);
    }
    else
    {
        TextureColor = texture(TestTexture, vOutTexelData);
    }
    
    if(TextureColor.a == 0.0)
    {
        discard;
    }
    vFragColor = TextureColor * vOutColor;
}
#endif
END
