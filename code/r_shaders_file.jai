BASIC_SHADER_SOURCE_TEXT :: #string END
#define RO_NONE          0 
#define RO_TEXEL_FETCHED 0x01
#define RO_UNLIT         0x02

struct light_attenuation_data
{
    float Constant;
    float Linear;
    float Quadratic;
};

struct point_light
{
    vec4                   Color;
    vec2                   vsPosition;
    vec2                   Direction;
    float                  SpotAngle;
    light_attenuation_data Attenuation;
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

     out vec4 vOutColor; 
     out vec2 vOutTexelData;
     out vec3 vOutVSNormals;
     out vec4 vOutFragPos;
flat out uint vOutRenderingOptions;
flat out uint vOutTexIndex;

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
layout(std140, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

uniform int       uPointLightCount;
uniform float     uAmbientLighting;
uniform sampler2D uAtlasArray[16];

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

    vec3  Normal       = vOutVSNormals;
    vec3  FragPos      = vOutFragPos.xyz;
    vec3  AmbientLight = vec3(uAmbientLighting);

    vec3 TotalLighting = vec3(0);
    for(uint LightIndex = 0;
        LightIndex < uPointLightCount;
        ++LightIndex)
    {
        point_light Light = PointLights[LightIndex];
        vec3  LightDir  = normalize(vec3(Light.vsPosition, 0.0) - FragPos);
        float LightDist = length(vec3(Light.vsPosition, 0.0) - FragPos);

        float Attenuation = 1.0 / (Light.Attenuation.Constant  + 
                                   Light.Attenuation.Linear    * LightDist  + 
                                   Light.Attenuation.Quadratic * (LightDist * LightDist));
        vec3 DiffuseLighting = DiffuseColor.rgb * Light.Color.rgb * Attenuation * (1.0 - LightDist);
        TotalLighting += Light.Color.rgb;
    }

    vFragColor = vec4(DiffuseColor.rgb * AmbientLight + TotalLighting, DiffuseColor.a);
    //vFragColor = vec4(DiffuseColor.rgb * AmbientLight + TotalLighting, DiffuseColor.a) * vOutColor;
}
#endif
END
