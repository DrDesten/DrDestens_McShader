#if !defined PBR_READ_GLSL
#define PBR_READ_GLSL

uniform sampler2D colortex3;

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

#endif