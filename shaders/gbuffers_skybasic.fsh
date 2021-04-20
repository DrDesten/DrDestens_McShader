#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/skyColor.glsl"

//#define FAST_SKY

#ifdef FAST_SKY
    in vec3 skyColor;
#endif
in vec2 coord;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

/* DRAWBUFFERS:04 */

void main() {

    #ifdef FAST_SKY

        vec3 color = skyColor;

    #else

        vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
        vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;

        vec3 color = getSkyColor(viewPos.xyz); //Get sky

    #endif

    FD0 = vec4(color, 1.0);
    FD1 = vec4(0);
}