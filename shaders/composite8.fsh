#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"
#include "/lib/bloom.glsl"

in vec2 coord;


/* DRAWBUFFERS:5 */
void main() {
    float blursize = 3 / viewHeight;
    vec3 color = gBlur_v16_bloom(coord * 0.25, blursize);

    color = saturation(color, 0.3);

    FD0 = vec4(color, 1);
}