#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"
#include "/lib/bloom.glsl"

in vec2 coord;


/* DRAWBUFFERS:5 */
void main() {
    float blursize = 2 / viewHeight;
    vec3 color = gBlur_v6_bloom_c(coord * 0.05, blursize, 0.05 - 1.5/viewHeight);

    FD0 = vec4(color, 1);
}