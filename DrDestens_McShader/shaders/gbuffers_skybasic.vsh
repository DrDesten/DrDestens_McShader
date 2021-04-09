#version 130

#include "/lib/math.glsl"
#include "/lib/skyColor.glsl"

//#define FAST_SKY

#ifdef FAST_SKY
    varying vec3 skyColor;
#endif
varying vec2 texcoord;

void main() {
    gl_Position = ftransform();

    #ifdef FAST_SKY
        vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
        skyColor = getSkyColor(viewPos);
    #endif

    texcoord = gl_MultiTexCoord0.xy;
}