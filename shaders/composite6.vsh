#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"

out vec2 coord;

void main() {
    vec4 clipPos = ftransform();
    gl_Position  = clipPos;
    coord        = gl_MultiTexCoord0.st;
}