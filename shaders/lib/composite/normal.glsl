uniform sampler2D colortex2; // Normal Buffer

vec3 getNormal(vec2 coord) {
    return texture(colortex2, coord).rgb;
}
vec3 getNormal(vec2 coord, float lod) {
    return texture(colortex2, coord, lod).rgb;
}

vec3 getNormal(ivec2 icoord) {
    return texelFetch(colortex2, icoord, 0).rgb;
}
vec3 getNormal(ivec2 icoord, int lod) {
    return texelFetch(colortex2, icoord, lod).rgb;
}