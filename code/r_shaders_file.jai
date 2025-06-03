BASIC_SHADER_SOURCE_TEXT :: #string END
#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec2 vTexelData;

uniform mat4 ProjectionMatrix;
uniform mat4 ViewMatrix;

out vec4 vOutColor; 
out vec2 vOutTexelData;

void
main()
{
    vOutColor     = vColor;
    vOutTexelData = vTexelData;
    gl_Position   = ProjectionMatrix * ViewMatrix * vPosition;
}
#endif

#ifdef FRAGMENT_SHADER
layout(location = 0) in vec4 vOutColor;
layout(location = 1) in vec2 vOutTexelData;

out vec4 vFragColor;

layout(binding = 0) uniform sampler2D TestTexture;

void
main()
{
    vec4 TextureColor = texture(TestTexture, vOutTexelData);
    if(TextureColor.a == 0.0)
    {
        discard;
    }
    vFragColor = TextureColor * vOutColor;
}
#endif
END
