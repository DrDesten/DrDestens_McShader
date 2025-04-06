uniform sampler2D colortex3; // Lightmap & AO Buffer

vec3 getLightmapData(vec2 coord) {
    return texture(colortex3, coord).rgb;
}
vec3 getLightmapData(vec2 coord, float lod) {
    return texture(colortex3, coord, lod).rgb;
}

vec3 getLightmapData(ivec2 icoord) {
    return texelFetch(colortex3, icoord, 0).rgb;
}
vec3 getLightmapData(ivec2 icoord, int lod) {
    return texelFetch(colortex3, icoord, lod).rgb;
}