#define RO_NONE          0x00 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02
#define RO_OCCLUDER      0x04
struct point_light
{
    vec4                   Color;
    vec2                   vsPosition;
    vec2                   csPosition;
    vec2                   Direction;
    float                  SpotAngle;
    float                  Radius;
    float                  Strength; 
    float                  padding[3];
};

#define PI 3.1415926535

#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec3 vVSNormals;
layout(location = 3) in vec2 vTexelData;
layout(location = 4) in uint vRenderingOptions;
layout(location = 5) in uint vTextureIndex;
layout(location = 6) in uint vRenderLayer;

uniform mat4 uProjectionMatrix;

out vec4 vColorMask;
out vec2 vAtlasUVs;

out flat uint InstanceID;

void
main()
{
    vColorMask  = vColor;
    vAtlasUVs   = vTexelData;
    InstanceID  = vTextureIndex;

    gl_Position = uProjectionMatrix * vPosition;
}
#endif

#ifdef FRAGMENT_SHADER
layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

in vec4 vColorMask;
in vec2 vAtlasUVs;

in flat uint InstanceID;

out vec4 vFragColor;

void
main()
{
    const float TileSize = 4.0;
    
    point_light Light = PointLights[InstanceID];
    vec2 FragPos      = gl_FragCoord.xy;
    vec2 FragTilePos    = floor(FragPos.xy / TileSize) * TileSize + TileSize * 0.5;

    vec2 LightPos     = {128, 128};
    vec2 LightDir     = normalize(vec2(LightPos - FragTilePos));
    vec2 SpotlightDir = normalize(Light.Direction);

    vec2  FragToLight  = FragPos - LightPos;
    float cosTheta     = dot(SpotlightDir, normalize(FragToLight));
    float cosSpotAngle = cos(Light.SpotAngle);
    float LightDist    = length(LightPos - FragTilePos);

    if(LightDist > Light.Radius) return;

    float SpotEffect;
    float EdgeDelta = 0.087;
    if(Light.SpotAngle < PI)
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

    float SpotStrength = SpotEffect * Light.Strength;
    vec4  LightContrib = (1.0 - exp(-0.5 * SpotStrength)) * vColorMask;
            
    vec4 EffectiveLightColor = LightContrib;

    vFragColor    = EffectiveLightColor;
}
#endif
