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

#define PI  3.1415926535
#define TAU 6.283185307 

#ifdef VERTEX_SHADER
out vec2 vOutTexelData;

void
main()
{
    vec2 csPosition[6] = 
    {
        vec2(-1,  1), // Top-left
        vec2( 1,  1), // Top-right
        vec2(-1, -1), // Bottom-left
        vec2(-1, -1), // Bottom-left
        vec2( 1, -1), // Bottom-right
        vec2( 1,  1), // Top-right
    };

    vec2 UVData[6] = 
    {
        vec2(0.0, 1.0), 
        vec2(1.0, 1.0), 
        vec2(0.0, 0.0), 
        vec2(0.0, 0.0), 
        vec2(1.0, 0.0), 
        vec2(1.0, 1.0), 
    };

    vOutTexelData = UVData[gl_VertexID];
    gl_Position   = vec4(csPosition[gl_VertexID], 0.0, 1.0);
}
#endif

#ifdef FRAGMENT_SHADER
layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

uniform uint uPointLightCount;

layout(binding = 0) uniform sampler2D uPositionTexture;
layout(binding = 1) uniform sampler2D uShadowMap;

in  vec2 vOutTexelData;
out vec4 vFragColor;

void
main()
{
    vec3 TotalLighting    = vec3(0.0);
    vec2 FragmentPosition = texture(uPositionTexture, vOutTexelData).xy;

    for(uint LightIndex  = 0;
        LightIndex < uPointLightCount;
        ++LightIndex)
    {
        point_light WorkingLight = PointLights[LightIndex];
        vec2  Distance = FragmentPosition - WorkingLight.vsPosition;
        float LightToFrag = length(Distance);
        if(LightToFrag > WorkingLight.Radius) continue;

        // NOTE(Sleepster): This is angle from the fragment to the light 
        float Theta = atan(Distance.y, Distance.x);
        float U     = (Theta + PI) / (TAU);
        float V     = (float(LightIndex) + 0.50) / float(uPointLightCount);

        // NOTE(Sleepster): Shadow Map Dist 
        float sm_Distance      = texture(uShadowMap, vec2(mod(U, 1.0), V)).r;
        float UnnormalizedDist = sm_Distance * WorkingLight.Radius;

        float ShadowBias  = 5.0;
        float ShadowAmount = (LightToFrag >= UnnormalizedDist + ShadowBias) ? 1.0 : 0.0;

        float Attenuation  = max(0.0, 1.0 - (LightToFrag / WorkingLight.Radius));
        vec3  LightContrib = WorkingLight.Color.rgb * Attenuation * (1.0 - ShadowAmount) * WorkingLight.Strength;

        TotalLighting += LightContrib;
    }

    vFragColor = vec4(TotalLighting, 1.0);
}
#endif
