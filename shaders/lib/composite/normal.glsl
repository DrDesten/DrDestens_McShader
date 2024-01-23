uniform sampler2D colortex1; // Normal Buffer

vec3 getNormal(vec2 coord) {
    return texture(colortex1, coord).rgb;
}
vec3 getNormal(vec2 coord, float lod) {
    return texture(colortex1, coord, lod).rgb;
}

vec3 getNormal(ivec2 icoord) {
    return texelFetch(colortex1, icoord, 0).rgb;
}
vec3 getNormal(ivec2 icoord, int lod) {
    return texelFetch(colortex1, icoord, lod).rgb;
}