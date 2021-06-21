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

/* DRAWBUFFERS:0 */
void main() {
    vec3 color = getAlbedo(coord);
    
    vec2 bloomCoord = clamp(coord * 0.25, 0, 0.25 - 1 / viewHeight);
    vec3 bloomColor = (texture(colortex5, bloomCoord).rgb);

    color += (bloomColor * bloomColor) * BLOOM_AMOUNT * 5;
    //color = bloomColor;

    FD0 = vec4(color, 1);
}