#if ! defined PBR_READ_GLSL
#define PBR_READ_GLSL

#include "structs.glsl"
#include "/core/core.glsl"

/*
vec4 encodeMaterial(MaterialTexture material, ivec2 fragCoord) {
    vec4 encoded;

    encoded.x = material.lightmap.x;
    encoded.y = material.lightmap.y;
    encoded.z = material.ao;
    
    int id = getCoordinateId(fragCoord);
    if (id == 0) encoded.w = material.roughness;
    if (id == 1) encoded.w = material.reflectance;
    if (id == 2) encoded.w = material.height;
    if (id == 3) encoded.w = material.emission;

    return encoded;
}
MaterialTexture decodeMaterial(vec4 samples[4], int ids[4]) {
    MaterialTexture material;

    material.lightmap.x = samples[0].x;
    material.lightmap.y = samples[0].y;
    material.ao   = samples[0].z;

    for (int i = 0; i < 4; i++) {
        if (ids[i] == 0) material.roughness   = samples[i].w;
        if (ids[i] == 1) material.reflectance = samples[i].w;
        if (ids[i] == 2) material.height      = samples[i].w;
        if (ids[i] == 3) material.emission    = samples[i].w;
    }

    return material;
}
MaterialTexture getPBR(ivec2 icoord) {
    vec4  samples[4];
    int   sampleIds[4];
    ivec2 sampleCoords[4];

    sampleCoords[0] = icoord;
    sampleCoords[1] = icoord + ivec2(-1, 0);
    sampleCoords[2] = icoord + ivec2(0, -1);
    sampleCoords[3] = icoord + ivec2(-1, -1);

    if (sampleCoords[1].x == -1) sampleCoords[1].x = 1;
    if (sampleCoords[2].y == -1) sampleCoords[1].y = 1;
    if (sampleCoords[3].x == -1) sampleCoords[1].x = 1;
    if (sampleCoords[3].y == -1) sampleCoords[1].y = 1;

    for (int i = 0; i < 4; i++) {
        samples[i]   = texelFetch(colortex3, sampleCoords[i], 0);
        sampleIds[i] = getCoordinateId(sampleCoords[i]);
    }

    return decodeMaterial(samples, sampleIds);
} 
*/

uniform sampler2D colortex7;

MaterialTexture getPBR(ivec2 icoord) {
    vec4 data = vec2x16to4(texelFetch(colortex7, icoord, 0).xy);
    return MaterialTexture(data.x, data.y, data.z, data.w);
}

#endif