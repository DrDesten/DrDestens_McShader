#version 130

/*
const int colortex0Format = RGB16F;      // Color
const int colortex2Format = RGB16_SNORM; // Normals

const int colortex4Format = R16F;        // Colortex4 = blockId
const int colortex5Format = RGB8;        // Colortex5 = bloom
*/

const float sunPathRotation = -40.0;


#include "/lib/settings.glsl"
#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"


in vec2 coord;

/* DRAWBUFFERS:2 */

void main() {
    vec3 normal         = getNormal(coord);

    //Pass everything forward
    FD0          = vec4(normal, 1);
}