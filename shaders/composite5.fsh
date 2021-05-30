#version 130


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                      MOTION BLUR
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

//#define MOTION_BLUR

uniform float near;
uniform float far;

uniform mat4 gbufferProjection;
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
    if (dot(blur, blur) < 0.008 / viewWidth) { return getAlbedo(coord); }

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
        vec2 motionBlurVector = coord - movecoord;
        vec3 color = vectorBlur(coord, motionBlurVector, 10);
    #else
        vec3 color = getAlbedo(coord);
    #endif

    #if 1 == 0
        float depth = getDepth(coord);
        float linearDepth = getLinearDepth(coord);

        vec4 sunProjection = gbufferProjection * vec4(sunPosition, 1.0);
        vec3 sunScreenSpace = (sunProjection.xyz / sunProjection.w) * 0.5 + 0.5;

        /* if (distance(clamp(sunScreenSpace.xy, 0, 1), coord) < 0.02) {
            color = vec3(1,0,0);
        } */
        
        float sunFade = 0.3;
        float sunDistance = length(sunScreenSpace.xy - clamp(sunScreenSpace.xy, sunFade, 1 - sunFade)) / sunFade;
        float distanceToSun = distance(coord, sunScreenSpace.xy);

        vec4 sunRayMarch = depthIntersectionMarch(vec3(coord, getDepth(coord)), (sunScreenSpace), 100);
        float lightShaft = clamp((sunRayMarch.w - sunDistance), 0, 1);
    #endif

    //Pass everything forward
    FD0          = vec4(color, 1);
}