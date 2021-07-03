#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"
#include "/lib/bloom.glsl"

const bool colortex5MipmapEnabled = true;

in vec2 coord;

/* DRAWBUFFERS:5 */

void main() {
    float blursize = 8 / viewHeight;
    vec3 color = gBlur_h6_bloom(coord * 0.25, blursize, 4);
    
    FD0 = vec4(color, 1);
}