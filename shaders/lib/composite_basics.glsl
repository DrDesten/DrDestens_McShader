uniform sampler2D colortex0; // Color
uniform sampler2D colortex2; // Normals

uniform sampler2D colortex3; // Type (BlockID)
uniform sampler2D depthtex0;

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

ivec2 convertIntCoords(vec2 coord, vec2 size) {
    return ivec2(coord * size);
}
vec2 blurOffset(vec2 coord, float lod) {
    return coord + (screenSizeInverse * 0.5 * (lod + 1));
}

vec3 getAlbedo(in vec2 coord) {
    return texture(colortex0, coord).rgb;
}
vec3 getAlbedo(in ivec2 icoord) {
    return texelFetch(colortex0, icoord, 0).rgb;
}


vec3 getNormal(in vec2 coord) {
    return texture(colortex2, coord).rgb;
}
vec3 getNormal(in ivec2 icoord) {
    return texelFetch(colortex2, icoord, 0).rgb;
}

float getDepth(in vec2 coord) {
    return texelFetch(depthtex0, convertIntCoords(coord, screenSize), 0).x;
}
float getDepth(in ivec2 icoord) {
    return texelFetch(depthtex0, icoord, 0).x;
}
float getDepth_int(in vec2 coord) {
    return texture(depthtex0, coord).x;
}

float getID(in vec2 coord) {
    return floor(texelFetch(colortex3, convertIntCoords(coord, screenSize), 0).r * 255 + 0.5);
}
float getID(in ivec2 icoord) {
    return floor(texelFetch(colortex3, icoord, 0).r * 255 + 0.5);
}
float getID_int(in vec2 coord) {
    return texture(colortex3, coord).r * 255;
}