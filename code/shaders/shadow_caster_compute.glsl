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

layout(binding = 0)     uniform sampler2D uOcclusionMap;
layout(r8, binding = 0) uniform image2D   uShadowMap;

void
main()
{
    ivec2 PixelCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2  ScreenSize = vec2(uTileSize) * uScreenTileSize;

    uint CurrentTileX = PixelCoord.x / uTileSize;
    uint CurrentTileY = PixelCoord.y / uTileSize;

    uint TileIndex      = CurrentTileX + CurrentTileY * uint(uScreenTileSize.x);
    int  TileLightCount = TileLightCount[TileIndex];

    // NOTE(Sleepster): This is because the GPU samples a pixel from the center of the pixel or texel 
    vec2 PixelPosition  = vec2(PixelCoord) + 0.5;
    for(uint LightIndex = 0;
        LightIndex < TileLightCount;
        ++LightIndex)
    {
        uint        CurrentLightIndex = LightIndices[TileIndex * uMaxLightsPerTileCluster + LightIndex];
        point_light CurrentLight      = PointLights[CurrentLightIndex];
    }
}























#if 0
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

layout(binding = 0)     uniform sampler2D uOcclusionMap;
layout(r8, binding = 0) uniform image2D   uShadowMap;

// TODO(Sleepster): This will be REALLLLLLLLLLLLLLLLY slow 
bool
RaymarchLight(vec2 LightPosition, vec2 PixelPosition)
{
    const int MaxMarches = 128;
    
    vec2  DirectionVector = normalize(PixelPosition - LightPosition);
    float Distance        = distance(LightPosition, PixelPosition);

    float StepDistance   = Distance / float(MaxMarches);

    vec2 ScreenSize = vec2(1920, 1080);
    for(uint MarchIndex = 0;
        MarchIndex < MaxMarches;
        ++MarchIndex)
    {
        vec2 Position = LightPosition + DirectionVector * StepDistance * MarchIndex;
        vec2 ScreenUV = Position / ScreenSize;

        if(texture(uOcclusionMap, ScreenUV).r > 0.5)
        {
            return(true);
        }
    }
    return(false);
}

void
main()
{
    ivec2 PixelCoord = ivec2(gl_GlobalInvocationID.xy);
    vec2  ScreenSize = vec2(1920, 1080);

    // uint CurrentTileX = PixelCoord.x / uTileSize;
    // uint CurrentTileY = PixelCoord.y / uTileSize;

    // uint TileIndex      = CurrentTileX + CurrentTileY * uint(uScreenTileSize.x);
    // int  TileLightCount = TileLightCount[TileIndex];

    // // NOTE(Sleepster): This is because the GPU samples a pixel from the center of the pixel or texel 
    // vec2 PixelPosition  = vec2(PixelCoord) + 0.5;
    // for(uint LightIndex = 0;
    //     LightIndex < TileLightCount;
    //     ++LightIndex)
    // {
    //     uint        CurrentLightIndex = LightIndices[TileIndex * uMaxLightsPerTileCluster + LightIndex];
    //     point_light CurrentLight      = PointLights[CurrentLightIndex];

    //     vec2 LightPosition = (CurrentLight.csPosition * 0.5 + 0.5) * vec2(1920, 1080);
    //     bool IsOcculuded   = RaymarchLight(LightPosition, PixelPosition);
    //     if(IsOcculuded)
    //     {
    //         imageStore(uShadowMap, PixelCoord, vec4(1.0));
    //     }
    // }

    vec2 uv = PixelCoord / ScreenSize;
    vec4 TestColor = texture(uOcclusionMap, uv);
    imageStore(uShadowMap, PixelCoord, TestColor);
}
#endif
