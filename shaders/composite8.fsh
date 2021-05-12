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
    float blursize = 1.5 / viewHeight;
    vec3 color = gBlur_vertical7_bloom_clamp((coord + (0.5 / ScreenSize)) * 0.25, blursize, 0.249);

    color = saturation(color, 0.3);

    FD0 = vec4(color, 1);
}