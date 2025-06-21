struct point_light
{
    vec4                   Color;
    vec2                   vsPosition;
    vec2                   Direction;
    float                  SpotAngle;
    float                  Radius;
    float                  Strength; 
    float                  padding;
};

#ifdef VERTEX_SHADER
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec3 vVSNormals;
layout(location = 3) in vec2 vTexelData;
layout(location = 4) in uint vRenderingOptions;
layout(location = 5) in uint vTextureIndex;

uniform mat4 uViewMatrix;

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

    gl_Position = vec4(Vertices[gl_VertexID], 0.0, 1.0);
}
#endif

#ifdef FRAGMENT_SHADER
layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

uniform int  uPointLightCount;
uniform vec2 uScreenSize;

out vec4 vFragColor;

void
main()
{
    vec4 vFragPos = gl_FragCoord - (vec4(uScreenSize, 0, 1) * vec4(0.5, 0.5, 0, 1));
    
    const float EdgeDelta = 0.087;
    const float TileSize  = 16.0;

    vec3 TotalLighting = vec3(0);
    for(uint LightIndex = 0;
        LightIndex < uPointLightCount;
        ++LightIndex)
    {
        point_light Light   = PointLights[LightIndex];
        vec2 FragTilePos    = floor(vFragPos.xy / TileSize) * TileSize + TileSize * 0.5;
        vec3 SnappedFragPos = vec3(FragTilePos, 1.0);

        vec3 LightPos           = vec3(Light.vsPosition, 0.0);
        vec3 LightDir           = normalize(LightPos - SnappedFragPos);
        vec3 SpotlightDirection = normalize(vec3(Light.Direction, 0.0));

        vec3 LightToFrag        = SnappedFragPos - LightPos;
        float cosTheta          = dot(SpotlightDirection, normalize(LightToFrag));
        float cosSpotAngle      = cos(Light.SpotAngle);
        float LightDist         = length(LightPos - SnappedFragPos);
        if (LightDist > Light.Radius) continue;

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

        float MaxSteps    = 500.0;
        float CurrentStep = floor((1.0 - (LightDist / Light.Radius)) * MaxSteps) / MaxSteps;
        float Attenuation = CurrentStep * (1.0 - (LightDist / Light.Radius));

        float SpotStrength = SpotEffect * Light.Strength;
        vec3  LightContrib = (1.0 - exp(-0.5 * SpotStrength)) * Light.Color.rgb;
        
        vec3 EffectiveLightColor = LightContrib;
        vec3 AdditiveLighting    = EffectiveLightColor * Attenuation;

        TotalLighting += EffectiveLightColor;
    }

    vec3 LitColor = TotalLighting;
    vFragColor    = vec4(LitColor, 1.0);
}
#endif
