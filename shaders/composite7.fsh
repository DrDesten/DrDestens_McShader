#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"
#include "/lib/bloom.glsl"

const bool colortex0MipmapEnabled = true;

in vec2 coord;

/* DRAWBUFFERS:5 */

void main() {
    float randfac = 0; // rand_11(-coord);
    float blursize = 8 / viewHeight;
    vec3 color = gBlur_h6_col(coord, blursize, 4);
    
    FD0 = vec4(color, 1);
}