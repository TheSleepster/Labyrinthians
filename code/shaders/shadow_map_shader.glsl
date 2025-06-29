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
layout(location = 0) in vec4 vPosition;
layout(location = 1) in vec4 vColor;
layout(location = 2) in vec3 vVSNormals;
layout(location = 3) in vec2 vTexelData;
layout(location = 4) in uint vRenderingOptions;
layout(location = 5) in uint vTextureIndex;

layout(location = 0) out vec2 vOutTexCoords;

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

    vec2 TexCoords[6] = 
        {
            vec2(0, 1), // Top-left
            vec2(1, 1), // Top-right
            vec2(0, 0), // Bottom-left
            vec2(0, 0), // Bottom-left
            vec2(1, 0), // Bottom-right
            vec2(1, 1), // Top-right
        };

    vOutTexCoords = TexCoords[gl_VertexID];
    gl_Position   = vec4(Vertices[gl_VertexID], 0.0, 1.0);
}

#endif

#ifdef FRAGMENT_SHADER
layout(std430, binding = 0) buffer PointLightSBO
{
    point_light PointLights[];
};

uniform uint uPointLightCount;
//uniform vec2 uScreenSize;

layout(location = 0) in      vec2      vOutTexCoords;
layout(binding  = 0) uniform sampler2D uOcclusionMap;

layout(location = 0) out vec4 vShadowMask;

void
main()
{
    vec4 TotalLighting = vec4(0.0);
    for (uint LightIndex = 0;
         LightIndex < uPointLightCount;
         ++LightIndex)
    {
        point_light Light    = PointLights[LightIndex];
        vec2 LightFragCoord  = Light.csPosition * 0.5 + 0.5;
        vec2 LightToFragDist = vOutTexCoords - LightFragCoord;
        float LightDistance  = length(LightToFragDist);

        if (LightDistance < Light.Radius)
        {
            // NOTE(Sleepster): MarchCount controls the pixelly appearance 
            const int MarchCount = 40;
            bool InShadow        = false;

            ivec2 OcclusionStrength = textureSize(uOcclusionMap, 0);
            for(int StepIndex = 1;
                StepIndex <= MarchCount;
                ++StepIndex)
            {
                float Step     = float(StepIndex) / float(MarchCount);
                vec2 SamplePos = LightFragCoord + Step * LightToFragDist;

                vec2  PixelPos         = SamplePos * vec2(OcclusionStrength);
                vec2  RoundedPixelPos  = floor(PixelPos + 0.5);
                vec2  SnappedSamplePos = RoundedPixelPos / vec2(OcclusionStrength);

                float SampleDistance   = Step * LightDistance;
                if(SampleDistance >= Light.Radius)
                {
                    break;
                }

                vec4 Occlusion = texture(uOcclusionMap, SnappedSamplePos);
                if(Occlusion.r > 0.5)
                {
                    InShadow = true;
                    break; 
                }
            }

            if(InShadow)
            {
                TotalLighting += vec4(0.1, 0.0, 0.0, 1.0); 
            }
        }
    }
    vShadowMask = TotalLighting;
}
#endif
