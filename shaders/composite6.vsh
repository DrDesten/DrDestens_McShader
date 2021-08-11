#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"

out vec2 coord;
#if MOTION_BLUR_QUALITY == 1
    out vec2 movement;
#endif

void main() {
    vec4 clipPos = ftransform();
    gl_Position  = clipPos;

    #if MOTION_BLUR_QUALITY == 1
        vec3 pos = vec3(0, 0, 1); //Clip position
        pos      = previousReprojectClip(pos);
        movement = pos.xy * MOTION_BLUR_STRENGTH * 0.5;
    #endif

    coord        = gl_MultiTexCoord0.st;
}