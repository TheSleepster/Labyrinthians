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
