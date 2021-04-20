#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

varying vec3 tintColor;


void main() {
    FD0 = vec4(tintColor, 1.0);
    FD1 = vec4(0,0,0,1);
}