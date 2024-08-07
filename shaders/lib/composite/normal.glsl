uniform sampler2D colortex1; // Normal Buffer

vec3 getNormal(vec2 coord) {
    return spheremapDecode(texture(colortex1, coord).rg);
}
vec3 getNormal(vec2 coord, float lod) {
    return spheremapDecode(texture(colortex1, coord, lod).rg);
}

vec3 getNormal(ivec2 icoord) {
    return spheremapDecode(texelFetch(colortex1, icoord, 0).rg);
}
vec3 getNormal(ivec2 icoord, int lod) {
    return spheremapDecode(texelFetch(colortex1, icoord, lod).rg);
}