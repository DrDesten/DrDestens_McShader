#version 130

#include "/lib/framebuffer.glsl"

uniform float far;

varying vec3 tintColor;
varying vec3 normal;
varying vec4 texcoord;


void main() {
    /* DRAWBUFFERS:0124 */

    COLORTEX_0 = vec4(tintColor,1);
    COLORTEX_1 = vec4(1);
    COLORTEX_2 = vec4(normal, 1);
    gl_FragData[3] = vec4(1.0);
}