#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

in vec2 coord;

vec3 gaussianHorizontal5(vec2 coord, float size) {
    vec3 color;
    color += getAlbedo_int(vec2(coord.x - size - size, coord.y)) * 0.06136;
    color += getAlbedo_int(vec2(coord.x - size, coord.y)) * 0.24477;
    color += getAlbedo_int(vec2(coord.x, coord.y)) * 0.38774;
    color += getAlbedo_int(vec2(coord.x + size, coord.y)) * 0.24477;
    color += getAlbedo_int(vec2(coord.x + size + size, coord.y)) * 0.06136;
    return color;
}
vec3 gaussianHorizontal7(vec2 coord, float size) {
    vec3 color;
    color += getAlbedo_int(vec2(coord.x - (size * 3), coord.y)) * 0.00598;
    color += getAlbedo_int(vec2(coord.x - size - size, coord.y)) * 0.060626;
    color += getAlbedo_int(vec2(coord.x - size, coord.y)) * 0.241843;
    color += getAlbedo_int(vec2(coord.x, coord.y)) * 0.383103;
    color += getAlbedo_int(vec2(coord.x + size, coord.y)) * 0.241843;
    color += getAlbedo_int(vec2(coord.x + size + size, coord.y)) * 0.060626;
    color += getAlbedo_int(vec2(coord.x + (size * 3), coord.y)) * 0.00598;
    return color;
}

/* DRAWBUFFERS:5 */

void main() {
    vec3 color = gaussianHorizontal7(coord, 4 / viewWidth);
    
    FD0 = vec4(color, 1);
}