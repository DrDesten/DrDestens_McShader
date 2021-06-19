#version 130


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                      MOTION BLUR
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

//#define MOTION_BLUR
#define MOTION_BLUR_STRENGTH 0.50 // [0.00  0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]
#define MOTION_BLUR_SAMPLES 4
//#define MOTION_BLUR_FULL

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
    vec2 sample   = coord - (blur * 0.5);

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
            vec2  motionBlurVector = coord - movecoord;

        #else

            // Motion Blur dependent on player Movement and Camera
            vec3  clipPos          = vec3(coord, getDepth(coord)) * 2 - 1;
            vec2  motionBlurVector = (coord - clamp(previousReproject(clipPos).xy, 0, 1)) * float(clipPos.z > 0.12);
            motionBlurVector      *= MOTION_BLUR_STRENGTH;

        #endif

        float ditherOffset         = (Bayer4(coord * ScreenSize) - 0.5) / (MOTION_BLUR_SAMPLES);
        vec3  color                = vectorBlur(coord + motionBlurVector * ditherOffset, motionBlurVector, MOTION_BLUR_SAMPLES);

    #else

        vec3  color = getAlbedo(coord);

    #endif

    //Pass everything forward
    FD0          = vec4(color, 1);
}