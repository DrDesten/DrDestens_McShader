uniform sampler2D colortex0; // Color
uniform sampler2D colortex2; // Normals

uniform sampler2D colortex3; // Type (BlockID)
uniform sampler2D depthtex0;

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

#define FD0 gl_FragData[0]
#define FD1 gl_FragData[1]
#define FD2 gl_FragData[2]
#define FD3 gl_FragData[3]


ivec2 convertIntCoords(vec2 coord, vec2 size) {
    return ivec2(coord * size);
}
vec2 blurOffset(vec2 coord, float lod) {
    return coord + (screenSizeInverse * 0.5 * (lod + 1));
}


vec3 getAlbedo(in vec2 coord) {
    //return texture(colortex0, coord).rgb;
    return texelFetch(colortex0, convertIntCoords(coord, screenSize), 0).rgb;
}
vec3 getAlbedo_int(in vec2 coord) {
    return texture(colortex0, coord).rgb;
}

vec3 getNormal(in vec2 coord) {
    return texture(colortex2, coord).rgb;
}

float getDepth(in vec2 coord) {
    return texelFetch(depthtex0, convertIntCoords(coord, screenSize), 0).x;
}
float getDepth_int(in vec2 coord) {
    return texture(depthtex0, coord).x;
}

float getType(in vec2 coord) {
    return floor(texelFetch(colortex3, convertIntCoords(coord, screenSize), 0).r + 0.5);
}
float getType_int(in vec2 coord) {
    return texture(colortex3, coord).r;
}