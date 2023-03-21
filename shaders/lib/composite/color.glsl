uniform sampler2D colortex0; // Color Buffer

vec3 getAlbedo(vec2 coord) {
    return texture(colortex0, coord).rgb;
}
vec3 getAlbedo(vec2 coord, float lod) {
    return texture(colortex0, coord, lod).rgb;
}

vec3 getAlbedoLod(vec2 coord, float lod) {
    return textureLod(colortex0, coord, lod).rgb;
}

vec3 getAlbedo(ivec2 icoord) {
    return texelFetch(colortex0, icoord, 0).rgb;
}
vec3 getAlbedo(ivec2 icoord, int lod) {
    return texelFetch(colortex0, icoord, lod).rgb;
}