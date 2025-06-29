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

layout(location = 0) out vec4 vOutFragPos;

void
main()
{
    vec2 Vertices[6] = 
    {
        vec2(-1,  1), // Top-left
        vec2( 1,  1), // Top-right
        vec2(-1, -1), // Bottom-left
        vec2(-1, -1), // Bottom-left
        vec2( 1, -1), // Bottom-right
        vec2( 1,  1), // Top-right
    };

    vOutFragPos = inverse(uProjectionMatrix) * vec4(Vertices[gl_VertexID], 0.0, 1.0);
    gl_Position = vec4(Vertices[gl_VertexID], 0.0, 1.0);
}
#endif

#ifdef FRAGMENT_SHADER
uniform int  uPointLightCount;


layout(std140, binding = 0) uniform uPointLight
{
    vec4                   Color;
    vec2                   vsPosition;
    vec2                   csPosition;
    vec2                   Direction;
    float                  SpotAngle;
    float                  Radius;
    float                  Strength; 
    float                  padding[3];
}Light;

layout(location = 0) in vec4 vOutFragPos;

out vec4 vFragColor;

void
main()
{
    vec3 FragPos      = vOutFragPos.xyz;

    const float TileSize = 3.0;
    vec3 TotalLighting = vec3(0);
    vec3 Specular      = vec3(0);

    const float EdgeDelta = 0.087;
    vec2 FragTilePos    = floor(FragPos.xy / TileSize) * TileSize + TileSize * 0.5;
    vec3 SnappedFragPos = vec3(FragTilePos, FragPos.z);

    vec3 LightPos           = vec3(Light.vsPosition, 0.0);
    vec3 LightDir           = normalize(LightPos - SnappedFragPos);
    vec3 SpotlightDirection = normalize(vec3(Light.Direction, 0.0));

    vec3  LightToFrag       = SnappedFragPos - LightPos;
    float cosTheta          = dot(SpotlightDirection, normalize(LightToFrag));
    float cosSpotAngle      = cos(Light.SpotAngle);
    float LightDist         = length(LightPos - SnappedFragPos);
    if (LightDist > Light.Radius) return;

    float SpotEffect;
    if (Light.SpotAngle < 3.1415926535)
    {
        float OuterAngle    = Light.SpotAngle;
        float InnerAngle    = max(0.0, Light.SpotAngle - EdgeDelta);

        float cosOuter      = cos(OuterAngle);
        float cosInner      = cos(InnerAngle);

        float AngularEffect = smoothstep(cosOuter, cosInner, cosTheta);
        float RadialEffect  = smoothstep(Light.Radius, 0.0, LightDist);

        SpotEffect = AngularEffect * RadialEffect;
    }
    else
    {
        SpotEffect = pow(1 - LightDist / Light.Radius, 2.5);
    }

    float Attenuation       = SpotEffect * Light.Strength;
    vec3  DiffuseLighting   = Light.Color.rgb * Attenuation;

    TotalLighting = DiffuseLighting * vec3(0.01); 
    vFragColor    = vec4(TotalLighting.rgb, Attenuation);
}

#endif
