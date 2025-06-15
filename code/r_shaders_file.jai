// TEST :: #string END
// #load "Shader_File.glsl";
// END

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
                SpotEffect = pow(1 - LightDist / Light.Radius, 2.5);
            }

            float MaxSteps    = 500.0;
            float CurrentStep = floor((1.0 - (LightDist / Light.Radius)) * MaxSteps) / MaxSteps;
            float Attenuation = CurrentStep * (1.0 - (LightDist / Light.Radius));

            float Shine            = Material.ShineStrength == 0.0 ? 128.0 : Material.ShineStrength;
            vec3 ReflectDir        = reflect(-LightDir, Normal);
            float SpecularLighting = pow(max(dot(Normal, ReflectDir), 0.0), Shine);

            float SpotStrength = SpotEffect * Light.Strength;
            vec3  LightContrib = (1.0 - exp(-0.5 * SpotStrength)) * Light.Color.rgb;
            
            vec3 EffectiveLightColor = LightContrib;
            vec3 AdditiveLighting    = EffectiveLightColor * Attenuation;

            TotalLighting += EffectiveLightColor;
            Specular      += 0.5 * SpecularLighting * Light.Color.rgb;
        }

        vec3 Color    = DiffuseColor.rgb;
        vec3 LitColor = Color * AmbientLight + (1.0 - Color) * TotalLighting;
        vFragColor    = vec4(LitColor, DiffuseColor.a);
    }
    else
    {
        vFragColor = DiffuseColor;
    }
}
#endif
END

LIGHTMAP_SHADER_TEXT :: #string END
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

    gl_Position   = vec4(Vertices[gl_VertexID], 0.0, 1.0);
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
END

LIGHT_CLUSTERING_COMPUTE_SHADER :: #string END
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

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

layout(std430, binding = 1) buffer LightIndicesSBO
{
    int LightIndices[];
};

layout(std430, binding = 2) buffer TileLightCountSBO
{
    int TileLightCount[];
};

uniform int  uLightCount;
uniform int  uTileSize;
uniform int  uMaxLightsPerTileCluster;
uniform vec2 uScreenTileSize;

bool
CircleAABBTest(vec2 TileMin, vec2 TileMax, vec2 LightPos, float LightRadius)
{
    bool Result = false;
    vec2 ClosestVector = clamp(LightPos, TileMin, TileMax);

    Result = (distance(ClosestVector, LightPos) <= LightRadius);
    return(Result);
}

void
main()
{
    uint TileX = gl_GlobalInvocationID.x;
    uint TileY = gl_GlobalInvocationID.y;
    if(TileX > int(uScreenTileSize.x) || TileY > int(uScreenTileSize.y))
    {
        return;
    }

    vec2 TileMin   = vec2(TileX * uTileSize, TileY * uTileSize);
    vec2 TileMax   = vec2((TileX + 1) * uTileSize, (TileY + 1) * uTileSize);
    uint TileIndex = TileX + TileY * int(uScreenTileSize.x);

    int TileLightCounter = 0;

    for(int LightIndex = 0;
        LightIndex < uLightCount;
        ++LightIndex)
    {
        point_light Light = PointLights[LightIndex];
        if(CircleAABBTest(TileMin, TileMax, Light.vsPosition, Light.Radius))
        {
            if(TileLightCounter < uMaxLightsPerTileCluster)
            {
                uint i_LightIndex = TileIndex * uint(uMaxLightsPerTileCluster) + uint(TileLightCounter);
                LightIndices[i_LightIndex] = LightIndex;
                TileLightCounter++;
            }
        }
    }

    TileLightCount[TileIndex] = TileLightCounter;
}
END

FINAL_STAGE_MIXING_SHADER :: #string END
END
