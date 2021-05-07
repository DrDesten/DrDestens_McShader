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
vec3 gaussianVertical7_clamp(vec2 coord, float size, float maximum) {
    vec3 color;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y - (size * 3)), 0, maximum)).rgb * 0.00598;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y - size - size), 0, maximum)).rgb * 0.060626;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y - size), 0, maximum)).rgb * 0.241843;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y), 0, maximum)).rgb * 0.383103;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y + size), 0, maximum)).rgb * 0.241843;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y + size + size), 0, maximum)).rgb * 0.060626;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y + (size * 3)), 0, maximum)).rgb * 0.00598;
    return color;
}

vec3 saturation(vec3 col, float saturation) {
    float brightness = dot(col, vec3(0.299, 0.587, 0.112));
    return mix(vec3(brightness), col, saturation);
}


/* DRAWBUFFERS:5 */
void main() {
    float randfac = 0;// rand_11(coord);
    float blursize = 1.5 / viewHeight;
    vec3 color = gaussianVertical7_clamp((coord + (1 / vec2(viewWidth, viewHeight))) * 0.25, blursize, 0.249);

    // Reduce saturation
    color = saturation(color, 0.25);

    FD0 = vec4(color, 1);
}