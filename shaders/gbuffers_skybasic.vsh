#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"

varying vec2 coord;
varying vec3 viewpos;

void main() {
    gl_Position = ftransform();

    viewpos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz;
    coord   = gl_MultiTexCoord0.xy;
}