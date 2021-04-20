#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

uniform float far;

varying vec3 tintColor;
varying vec3 normal;
varying vec4 texcoord;


void main() {
    /* DRAWBUFFERS:0124 */

    FD0 = vec4(tintColor,1);
    FD1 = vec4(1);
    FD2 = vec4(normal, 1);
    FD3 = vec4(1.0);
}