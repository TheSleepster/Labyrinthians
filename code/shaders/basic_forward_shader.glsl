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

uniform mat4 uProjectionMatrix;
uniform mat4 uViewMatrix;

layout(location = 0)      out vec4 vOutColor; 
layout(location = 1)      out vec2 vOutTexelData;
layout(location = 2)      out vec3 vOutVSNormals;
layout(location = 3)      out vec4 vOutFragPos;
layout(location = 4) flat out uint vOutRenderingOptions;
layout(location = 5) flat out uint vOutTexIndex;

void
main()
{
    vOutColor            = vColor;
    vOutTexelData        = vTexelData;
    vOutRenderingOptions = vRenderingOptions;
    vOutVSNormals        = vVSNormals;
    vOutTexIndex         = vTextureIndex;
    vOutFragPos          = uViewMatrix * vPosition;

    gl_Position          = uProjectionMatrix * uViewMatrix * vPosition;
}
#endif

#ifdef FRAGMENT_SHADER
layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

uniform int             uPointLightCount;
uniform float           uAmbientLighting;
uniform sampler2D       uAtlasArray[16];

layout(std140, binding = 1) uniform uMaterial
{
    vec4  AmbientColor;
    vec4  SpecularColor;
    vec4  ShineColor;

    float AmbientStrength;
    float SpecularStrength;
    float ShineStrength;
    float padding;
}Material;

layout(location = 0)      in vec4 vOutColor;
layout(location = 1)      in vec2 vOutTexelData;
layout(location = 2)      in vec3 vOutVSNormals;
layout(location = 3)      in vec4 vOutFragPos;
layout(location = 4) flat in uint vOutRenderingOptions;
layout(location = 5) flat in uint vOutTexIndex;

out vec4 vFragColor;

void
main()
{
    vec4 DiffuseColor;
    if(vOutTexIndex > 0)
    {
        if((vOutRenderingOptions & RO_TEXEL_FETCHED) != 0)
        {
            DiffuseColor = texelFetch(uAtlasArray[vOutTexIndex], ivec2(vOutTexelData), 0);
        }
        else
        {
            DiffuseColor = texture(uAtlasArray[vOutTexIndex], vOutTexelData);
        }
        
        if(DiffuseColor.a == 0.0)
        {
            discard;
        }
    }
    else
    {
        DiffuseColor = vOutColor;
    }
    DiffuseColor = DiffuseColor * vOutColor;

    vec3  Normal       = vOutVSNormals;
    vec3  FragPos      = vOutFragPos.xyz;
    vec3  AmbientLight = vec3(uAmbientLighting);
    
    const float TileSize = 4.0;
    vec3 TotalLighting = vec3(0);
    if((vOutRenderingOptions & RO_UNLIT) == 0)
    {
        for(uint LightIndex = 0;
            LightIndex < uPointLightCount;
            ++LightIndex)
        {
            point_light Light   = PointLights[LightIndex];

            vec2 FragTilePos    = floor(FragPos.xy / TileSize) * TileSize + TileSize * 0.5;
            vec3 SnappedFragPos = vec3(FragTilePos, FragPos.z);
            vec3 LightPos       = vec3(Light.vsPosition, 0.0);
            float LightDist     = length(LightPos - SnappedFragPos);

            if(LightDist > Light.Radius) continue;

            vec4 SampleValue    = texture(uAtlasArray[4], Light.LightAtlasUVs) * Light.LightAtlasColorMask; 
            vec4 Alpha          = vec4(SampleValue.r + SampleValue.g + SampleValue.b + SampleValue.a);
            vec4 TrueLightColor = Light.Color * Alpha;

            TotalLighting      += TrueLightColor.rgb;
        }

        vec4 Color    = DiffuseColor.rgba;
        vec3 LitColor = Color.rgb * AmbientLight + (1.0 - Color.rgb) * TotalLighting;
        vFragColor    = vec4(LitColor, Color.a);
    }
    else
    {
        vFragColor = DiffuseColor;
    }
}
#endif
