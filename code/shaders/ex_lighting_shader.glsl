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
layout(location = 0) in vec2 vPosition;

uniform uint uPointLightCount;

layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

layout(location = 0)      out vDistanceToLight;
layout(location = 1)      out vLightRadius;

void
main()
{
    if(gl_InstanceID < uPointLightCount) return;

    point_light WorkingLight = PointLights[gl_InstanceID];

    // NOTE(Sleepster): Should this be in World Space? 
    vec2 LightPos    = PointLights[lightIndex].vsPosition;
    vLightRadius     = PointLights[lightIndex].radius;
    vDistanceToLight = vPosition - LightPos;

    float Angle = atan(vDistanceToLight.y, vDistnaceToLight.x);
    float U     = (Angle + 3.1415926535) / (6.283185307);
    float V     = (float(gl_InstanceID) + 0.5) / float(uPointLightCount);

    gl_Position = vec4(U * 2.0 - 1.0, V * 2.0 - 1.0, 0.0, 1.0);
}

#endif

#ifdef FRAGMENT_SHADER
layout(location = 0)      in vDistanceToLight;
layout(location = 1)      in vLightRadius;

void
main()
{
    if(vDistanceToLight > vLightRadius)
    {
        discard;
    }

    gl_FragDepth = vDistanceToLight / vLightRadius;
}

#endif
