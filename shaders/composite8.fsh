#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

uniform sampler2D colortex5;

in vec2 coord;

vec3 gaussianVertical5(vec2 coord, float size) {
    vec3 color;
    color += texture(colortex5, vec2(coord.x, coord.y - size - size)).rgb * 0.06136;
    color += texture(colortex5, vec2(coord.x, coord.y - size)).rgb * 0.24477;
    color += texture(colortex5, vec2(coord.x, coord.y)).rgb * 0.38774;
    color += texture(colortex5, vec2(coord.x, coord.y + size)).rgb * 0.24477;
    color += texture(colortex5, vec2(coord.x, coord.y + size + size)).rgb * 0.06136;
    return color;
}
vec3 gaussianVertical7(vec2 coord, float size) {
    vec3 color;
    color += texture(colortex5, vec2(coord.x, coord.y - (size * 3))).rgb * 0.00598;
    color += texture(colortex5, vec2(coord.x, coord.y - size - size)).rgb * 0.060626;
    color += texture(colortex5, vec2(coord.x, coord.y - size)).rgb * 0.241843;
    color += texture(colortex5, vec2(coord.x, coord.y)).rgb * 0.383103;
    color += texture(colortex5, vec2(coord.x, coord.y + size)).rgb * 0.241843;
    color += texture(colortex5, vec2(coord.x, coord.y + size + size)).rgb * 0.060626;
    color += texture(colortex5, vec2(coord.x, coord.y + (size * 3))).rgb * 0.00598;
    return color;
}

/* DRAWBUFFERS:5 */

void main() {
    vec3 color = gaussianVertical7(coord * 0.5, 2 / viewHeight);
    
    float brightness = sum(color);
    color = mix(color, vec3(brightness * 0.3333), 0.5);
    color *= brightness * 0.5;

    FD0 = vec4(color, 1);
}