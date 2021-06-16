#version 130

#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/skyColor.glsl"

//#define FAST_SKY

#ifdef FAST_SKY
    out vec3 skyColor;
#endif
out vec2 coord;

void main() {
    gl_Position = ftransform();

    #ifdef FAST_SKY
        vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
        skyColor = getSkyColor3(viewPos);
    #endif

    coord = gl_MultiTexCoord0.xy;
}