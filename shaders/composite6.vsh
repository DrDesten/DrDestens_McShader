#version 130

#include "/lib/settings.glsl"
#include "/lib/transform.glsl"

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