#version 130

#include "/lib/transform.glsl"

//#define MOTION_BLUR
#define MOTION_BLUR_STRENGTH 0.50 // [0.00  0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]
//#define MOTION_BLUR_FULL

out vec2 coord;
out vec2 movecoord;


void main() {
    vec4 clipPos = ftransform();

    #ifdef MOTION_BLUR

        #ifndef MOTION_BLUR_FULL
            movecoord = screenSpaceMovement(vec3(clipPos.xy, 1 - (MOTION_BLUR_STRENGTH * 0.016)), vec3(0.5, 1, 0.5)).xy;
        #else
            movecoord = vec2(0);
        #endif

    #else
        movecoord = vec2(0);
    #endif

    gl_Position = clipPos;
    coord = gl_MultiTexCoord0.st;
}