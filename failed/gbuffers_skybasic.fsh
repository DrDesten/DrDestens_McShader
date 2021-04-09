#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

varying vec3 tintColor;


void main() {
    COLORTEX_0 = vec4(tintColor, 1.0);
    COLORTEX_1 = vec4(0,0,0,1);
}