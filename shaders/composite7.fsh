#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/bloom.glsl"

in vec2 coord;

/* DRAWBUFFERS:5 */

void main() {
    float randfac = 0; // rand_11(-coord);
    float blursize = 6 / viewHeight;
    vec3 color = gBlur_horizontal7_color(coord + (0.5 / ScreenSize), blursize);
    
    FD0 = vec4(color, 1);
}