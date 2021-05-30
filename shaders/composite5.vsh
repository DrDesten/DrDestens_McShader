#version 130

#include "/lib/transform.glsl"

//#define MOTION_BLUR
#define MOTION_BLUR_STRENGTH 0.008 // [0.00 0.002 0.004 0.006 0.008 0.01 0.012 0.014 0.016 0.018 0.02 0.022 0.024 0.026 0.028 0.03]

out vec2 coord;
out vec2 movecoord;


void main() {
    vec4 clipPos = ftransform();

    #ifdef MOTION_BLUR

        movecoord = screenSpaceMovement(vec3(clipPos.xy, 1 - MOTION_BLUR_STRENGTH)).xy;

    #else
        movecoord = vec2(0);
    #endif

    gl_Position = clipPos;
    coord = gl_MultiTexCoord0.st;
}