#version 130


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                      MOTION BLUR
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

uniform float near;
uniform float far;

uniform vec3 sunPosition;

in vec2 coord;
in vec2 movecoord;

vec4 depthIntersectionMarch(vec3 startPos, vec3 endPos, float steps) {
    // Calculate Vector connecting startPos with endPos
    vec3 stepDirection = endPos - startPos;
    // Divide by step amount, to create the correct step size
    // I am dividing by "steps + 1":
    // If I would divide by steps, the last rayPos would be endPos (but we already know this point)
    // Diviting by "steps + 1", the last rayPos is one step before endPos, making endPos the next step, 
    //     which we can simply assume is the fallback if no intersection is found.
    stepDirection /= steps + 1;

    vec3 rayPos = startPos;
    rayPos += stepDirection * pattern_cross2(startPos.xy, 1, viewWidth, viewHeight) * 0.666;

    for (int i = 0; i < steps; i++) {
        // Incrementing the rayPos
        rayPos += stepDirection;

        float depth = getDepth_int(rayPos.xy);

        // Checking if the rayPos depth is "behind" the actual depth at that location
        if (depth + 0.0001 < rayPos.z) {
            float stepLength = length(rayPos - startPos);
            return vec4(rayPos.xy, depth, stepLength);
        }
    }

    return vec4(endPos, 1);
}

vec3 vectorBlur(vec2 coord, vec2 blur, int samples) {
    if (length(blur) < 1 / viewWidth) { return getAlbedo(coord); }

    vec3 col      = vec3(0);
    vec2 blurStep = blur / float(samples);
    vec2 sample   = coord;

    for (int i = 0; i < samples; i++) {
        col += getAlbedo_int(sample);
        sample += blurStep;
    }

    return col / float(samples);
}


/* DRAWBUFFERS:0 */
void main() {
    #ifdef MOTION_BLUR

        #ifndef MOTION_BLUR_FULL

            // Motion Blur only dependent on player Movement
            vec2  motionBlurVector = movecoord - coord;
            motionBlurVector      *= float(getDepth(coord) > 0.56);

        #else

            // Motion Blur dependent on player Movement and Camera
            vec3  clipPos          = vec3(coord, getDepth(coord)) * 2 - 1;
            vec3  prevCoord        = previousReproject(clipPos);
            vec2  motionBlurVector = (clamp(prevCoord.xy, -0.25, 1.25) - coord) * float(clipPos.z > 0.12);
            motionBlurVector      *= MOTION_BLUR_STRENGTH;

        #endif

        float ditherOffset         = (Bayer4(coord * ScreenSize) - 0.5) / (MOTION_BLUR_SAMPLES);
        vec3  color                = vectorBlur(coord + motionBlurVector * ditherOffset, motionBlurVector, MOTION_BLUR_SAMPLES);
        //color = abs(prevCoord.z - getDepth(coord)).xxx;

    #else

        vec3  color = getAlbedo(coord);

    #endif

    //Pass everything forward
    FD0          = vec4(color, 1);
}