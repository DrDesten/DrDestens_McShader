uniform sampler2D colortex0; // Color
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;


vec3 getAlbedo(ivec2 icoord) {
    return texelFetch(colortex0, icoord, 0).rgb;
}
vec3 getAlbedo(vec2 coord) {
    return texture(colortex0, coord).rgb;
}


float getDepth(ivec2 icoord) {
    return texelFetch(depthtex0, icoord, 0).x;
}
float getDepth(vec2 coord) {
    return texture(depthtex0, coord).x;
}


vec3 getNormal(vec2 coord) {
    return texture(colortex1, coord).rgb;
}
vec3 getNormal(ivec2 icoord) {
    return texelFetch(colortex1, icoord, 0).rgb;
}

vec2 getLmCoord(vec2 coord) {
    return texture(colortex2, coord).rg;
}



float getType(ivec2 icoord) {
    return floor(texelFetch(colortex3, icoord, 0).r * 255 + 0.5);
}
float getType(vec2 coord) {
    return floor(texture(colortex3, coord).r * 255 + 0.5);
}