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

uniform sampler2D colortex4;
uniform vec3 sunPosition;

in vec2 coord;

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


vec3 readBloomTile(vec2 coord, float initial_scale, float tile, float padding) {
    vec2 tileLocation = vec2(0);
    tileLocation.x    = 1 - exp2(-tile);
    tileLocation     += coord * exp2(-tile - 1);

    tileLocation     /= (initial_scale * .5);
    tileLocation.x   += padding * tile;

    return texture(colortex4, tileLocation).rgb;
}
vec3 readBloomTileBlur(vec2 coord, float initial_scale, float tile, float padding) {
    vec2 tileLocation = vec2(0);
    tileLocation.x    = 1 - exp2(-tile);
    tileLocation     += coord * exp2(-tile - 1);

    tileLocation     /= (initial_scale * .5);
    tileLocation.x   += padding * tile;

    vec3 color = vec3(0);
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {

            float weight = gaussian_5[x + 2] * gaussian_5[y + 2];
            vec2  offs   = vec2(x, y) * ScreenSizeInverse;

            vec2 sample  = tileLocation + offs;
            color       += texture(colortex4, sample).rgb * weight;

        }
    }

    return color;
}

/* DRAWBUFFERS:0 */
void main() {
    #ifdef MOTION_BLUR

        #if MOTION_BLUR_QUALITY == 0

            // Motion Blur dependent on player Movement and Camera
            vec3  clipPos      = vec3(coord, getDepth(coord)) * 2 - 1;
            vec3  prevCoord    = previousReproject(clipPos);

        #else
            
            vec3 clipPos       = vec3(coord * 2 -1, 1);
            vec3 prevCoord     = toView(clipPos);
            prevCoord          = toPlayerEye(prevCoord);

            prevCoord          = mat3(gbufferPreviousModelView) * prevCoord;
            prevCoord          = toPrevScreen(prevCoord);

        #endif
        
        vec2  motionBlurVector = (clamp(prevCoord.xy, -0.2, 1.2) - coord) * float(clipPos.z > 0.12);
        motionBlurVector      *= MOTION_BLUR_STRENGTH;

        float ditherOffset     = (Bayer4(coord * ScreenSize) - 0.5) / MOTION_BLUR_SAMPLES;
        vec3  color            = vectorBlur(motionBlurVector * ditherOffset + coord, motionBlurVector, MOTION_BLUR_SAMPLES);

    #else

        vec3  color = getAlbedo(coord);

    #endif

    #ifdef BLOOM
        vec3 bloom = vec3(0);
        for (int i = 0; i < 5; i++) {
            bloom += readBloomTile(coord, 4, i, 10 * ScreenSizeInverse.x);
        }
        bloom /= 5;
        color += sq(bloom) * BLOOM_AMOUNT;

        //color = readBloomTile(coord, 3, 4, 10 * ScreenSizeInverse.x);
    #endif


    //Pass everything forward
    FD0          = vec4(color, 1);
}