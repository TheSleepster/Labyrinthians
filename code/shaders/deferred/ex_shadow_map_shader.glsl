#define RO_NONE          0x00 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x10
#define RO_OCCLUDER      0x10
#define RO_NORMAL_MAPPED 0x11

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

#ifdef VERTEX_SHADER
layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec3 vVSNormals;
layout(location = 3) in vec2 vTexelData;
layout(location = 4) in uint vRenderingOptions;
layout(location = 5) in uint vTextureIndex;
layout(location = 6) in uint vRenderLayer;

uniform uint uPointLightCount;

layout(location = 0) out vec2  vDistanceToLight;
layout(location = 1) out float vLightRadius;

#define PI  3.1415926535
#define TAU 6.283185307 

void
main()
{
    uint LightIndex = gl_InstanceID;
    if(LightIndex > uPointLightCount) return;

    point_light WorkingLight = PointLights[LightIndex];

    // NOTE(Sleepster): Should this be in World Space? 
    vec2 LightPos    = WorkingLight.vsPosition;
    vDistanceToLight = vPosition.xy - LightPos;

    float Angle  = atan(vDistanceToLight.y, vDistanceToLight.x);
    float U      = ((Angle + PI) / (TAU));
    float V      = (float(LightIndex) + 0.50) / float(uPointLightCount);

    vLightRadius = WorkingLight.Radius;

    // NOTE(Sleepster): Add a small y-offset based on vertex ID, prevents the rasterizer
    // from failing to output any valid fragments for the fragment shader
    float DeltaY = (gl_VertexID % 2 == 0) ? -0.01: 0.01;
    gl_Position = vec4((U) * 2.0 - 1.0, ((V) * 2.0 - 1.0) + DeltaY, 0.0, 1.0);
}

#endif

#ifdef FRAGMENT_SHADER
layout(location = 0) in vec2  vDistanceToLight;
layout(location = 1) in float vLightRadius;

void
main()
{
    float Distance = length(vDistanceToLight);
    if(Distance > vLightRadius)
    {
        discard;
    }

    gl_FragDepth = Distance / vLightRadius;
}

#endif
