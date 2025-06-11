BASIC_SHADER_SOURCE_TEXT :: #string END
#define RO_NONE          0 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02
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
    
    const float TileSize = 16.0;
    vec3 TotalLighting = vec3(0);
    vec3 Specular      = vec3(0);
    if((vOutRenderingOptions & RO_UNLIT) == 0)
    {
        const float EdgeDelta = 0.087;
        for(uint LightIndex = 0;
            LightIndex < uPointLightCount;
            ++LightIndex)
        {
            point_light Light   = PointLights[LightIndex];
            vec2 FragTilePos    = floor(FragPos.xy / TileSize) * TileSize + TileSize * 0.5;
            vec3 SnappedFragPos = vec3(FragTilePos, FragPos.z);

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
                SpotEffect = smoothstep(Light.Radius, 0.0, LightDist);
                SpotEffect = pow(SpotEffect, 2.0);
            }

            float MaxSteps    = 500.0;
            float CurrentStep = floor((1.0 - (LightDist / Light.Radius)) * MaxSteps) / MaxSteps;
            float Attenuation = CurrentStep * (1.0 - (LightDist / Light.Radius));

            float Shine            = Material.ShineStrength == 0.0 ? 128.0 : Material.ShineStrength;
            vec3 ReflectDir        = reflect(-LightDir, Normal);
            float SpecularLighting = pow(max(dot(Normal, ReflectDir), 0.0), Shine);

            vec3 EffectiveLightColor =  Light.Color.rgb * SpotEffect;
            vec3 AdditiveLighting    = EffectiveLightColor * Attenuation;

            TotalLighting += EffectiveLightColor * Light.Strength;
            Specular      += 0.5 * SpecularLighting * Light.Color.rgb;
        }

        vFragColor = vec4(DiffuseColor.rgb * AmbientLight + TotalLighting + Specular, DiffuseColor.a);
    }
    else
    {
        vFragColor = DiffuseColor;
    }
}
#endif
END
