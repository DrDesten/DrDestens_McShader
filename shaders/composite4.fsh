#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                    DENOISE AND OUTLINE AND FOG
//////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

uniform sampler2D depthtex1;

uniform float frameTime; 
uniform float frameTimeCounter;
uniform int   frameCounter;
uniform int   worldTime;
uniform vec3  fogColor;
uniform vec3  sunPosition;
uniform vec3  moonPosition;

uniform float isInvisibleSmooth;
uniform float far;

uniform int   isEyeInWater;

in vec2 coord;

flat in vec2 x3_kernel[9];


/* // 3-Sample Dark Priority Despecler
    vec3 AntiSpeckleX2(vec2 coord, float threshold, float amount) {
        float pixelOffsetX = screenSizeInverse.x * amount;

        vec3 color           = getAlbedo(coord);

        vec3 color_surround[2]  = vec3[2](
            getAlbedo_int(vec2(coord.x + pixelOffsetX,  coord.y)),
            getAlbedo_int(vec2(coord.x - pixelOffsetX,  coord.y))
        );


        #ifdef DENOISE_DEBUG
        for (int i = 0; i < 2; i++) {
            if ((sum(color) - sum(color_surround[i])) > threshold) {color = vec3(1,0,0);}
        }
        #else

        for (int i = 0; i < 2; i++) {
            if ((sum(color) - sum(color_surround[i])) > threshold) {color = color_surround[i];}
        }

        #endif

        return color;
    }

    // 5-Sample Dark Priority Despecler
    vec3 AntiSpeckleX4(vec2 coord, float threshold, float amount) {
        vec2 pixelOffset = screenSizeInverse * amount;

        vec3 color           = getAlbedo(coord);
        vec2 coordOffsetPos  = coord + pixelOffset;
        vec2 coordOffsetNeg  = coord - pixelOffset;

        vec3 color_surround[4]  = vec3[4](
            getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetPos.y)),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetPos.y)),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetNeg.y)),
            getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetNeg.y))
        );


        #ifdef DENOISE_DEBUG
        for (int i = 0; i < 4; i++) {
            if ((sum(color) - sum(color_surround[i])) > threshold) {color = vec3(1,0,0);}
        }
        #else

        for (int i = 0; i < 4; i++) {
            if ((sum(color) - sum(color_surround[i])) > threshold) {color = color_surround[i];}
        }

        #endif

        return color;
    }

    // 9-Sample Dark Priority Despecler
    vec3 AntiSpeckleX8(vec2 coord, float threshold, float amount) {
        vec2 pixelOffset = screenSizeInverse * amount;

        vec3 color           = getAlbedo(coord);
        vec2 coordOffsetPos  = coord + pixelOffset;
        vec2 coordOffsetNeg  = coord - pixelOffset;

        vec3 color_surround[8]  = vec3[8](
            getAlbedo_int(vec2(coordOffsetPos.x,  coord.y         )),
            getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetPos.y)),
            getAlbedo_int(vec2(coord.x,           coordOffsetPos.y)),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetPos.y)),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coord.y         )),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetNeg.y)),
            getAlbedo_int(vec2(coord.x,           coordOffsetNeg.y)),
            getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetNeg.y))
        );

        #ifdef DENOISE_DEBUG
        for (int i = 0; i < 8; i++) {
            if ((sum(color) - sum(color_surround[i])) > threshold) {color = vec3(1,0,0);}
        }
        #else

        for (int i = 0; i < 8; i++) {
            if ((sum(color) - sum(color_surround[i])) > threshold) {color = color_surround[i];}
        }

        #endif

        return color;
    }

    // 3-Sample Closest-to-Average Denoiser
    vec3 DenoiseMeanL(vec2 coord, float threshold, float amount) {
        float pixelOffsetX = screenSizeInverse.x * amount;

        vec3 color           = getAlbedo(coord);

        vec3 color_surround[2]  = vec3[2](
            getAlbedo_int(vec2(coord.x + pixelOffsetX,  coord.y)),
            getAlbedo_int(vec2(coord.x - pixelOffsetX,  coord.y))
        );
        
        float average     = sum(color+color_surround[0]+color_surround[1]) / 3;
        float close       = abs(sum(color) - average);
        vec3 closestColor = color;

        for (int i = 0; i < 2; i++) {
            float diff = abs(sum(color_surround[i]) - average);
            if (diff < close) {
                close        = diff;
                closestColor = color_surround[i];
            }
        }

        return closestColor;
    }

    // 5-Sample Closest-to-Average Denoiser
    vec3 DenoiseMeanM(vec2 coord, float threshold, float amount) {
        vec2 pixelOffset = screenSizeInverse * amount;

        vec3 color           = getAlbedo(coord);
        vec2 coordOffsetPos  = coord + pixelOffset;
        vec2 coordOffsetNeg  = coord - pixelOffset;

        vec3 color_surround[4]  = vec3[4](
            getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetPos.y)),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetPos.y)),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetNeg.y)),
            getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetNeg.y))
        );

        float average     = sum(color+color_surround[0]+color_surround[1]+color_surround[2]+color_surround[3]) * 0.2;
        float close       = abs(sum(color) - average);
        vec3 closestColor = color;

        for (int i = 0; i < 4; i++) {
            float diff = abs(sum(color_surround[i]) - average);
            if (diff < close) {
                close        = diff;
                closestColor = color_surround[i];
            }
        }

        return closestColor;
    }

    // 9-Sample Closest-to-Average Denoiser
    vec3 DenoiseMeanH(vec2 coord, float threshold, float amount) {
        vec2 pixelOffset = screenSizeInverse * amount;

        vec3 color           = getAlbedo(coord);
        vec2 coordOffsetPos  = coord + pixelOffset;
        vec2 coordOffsetNeg  = coord - pixelOffset;

        vec3 color_surround[8]  = vec3[8](
            getAlbedo_int(vec2(coordOffsetPos.x,  coord.y         )),
            getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetPos.y)),
            getAlbedo_int(vec2(coord.x,           coordOffsetPos.y)),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetPos.y)),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coord.y         )),
            getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetNeg.y)),
            getAlbedo_int(vec2(coord.x,           coordOffsetNeg.y)),
            getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetNeg.y))
        );

        float average     = sum(color+color_surround[0]+color_surround[1]+color_surround[2]+color_surround[3]+color_surround[4]+color_surround[5]+color_surround[6]+color_surround[7]) / 9;
        float close       = abs(sum(color) - average);
        vec3 closestColor = color;

        for (int i = 0; i < 8; i++) {
            float diff = abs(sum(color_surround[i]) - average);
            if (diff < close) {
                close = diff;
                closestColor = color_surround[i];
            }
        }

        return closestColor;
    }
*/


float separationDetect(vec2 coord) {
    float edgeColor;
    float edgeColors[4] = float[](0,0,0,0);

    for (int i = 0; i < 9; i++) {
        float ccolor = getDepth_int(x3_kernel[i]);

        edgeColors[0] += ccolor * sobel_vertical[i];
        edgeColors[2] += ccolor * sobel_horizontal[i];

        edgeColors[1] += ccolor * -sobel_vertical[i];
        edgeColors[3] += ccolor * -sobel_horizontal[i];
    }

    edgeColor = abs(edgeColors[0]) + abs(edgeColors[1]) + abs(edgeColors[2]) + abs(edgeColors[3]);

    edgeColor = min(edgeColor * 2, 1);
    return edgeColor;
}

float depthEdgeFast(vec2 coord) {
    float depth         = getDepth(coord);
    // Use trick with linear interpolation to sample 16 pixels with 4 texture calls, and use the overall difference to calculate the edge
    float depthSurround = getDepth_int((screenSizeInverse * 1.5) + coord) + getDepth_int((screenSizeInverse * -1.5) + coord) + getDepth_int(vec2(screenSizeInverse.x * 1.5, screenSizeInverse.y * -1.5) + coord) + getDepth_int(vec2(screenSizeInverse.x * -1.5, screenSizeInverse.y * 1.5) + coord);
    depthSurround *= 0.25;

    return clamp((abs(depthSurround - depth) * 100. * OUTLINE_DISTANCE) - 0.075, 0, OUTLINE_BRIGHTNESS);
}

float depthEdge(vec2 coord) {
    float depth = getDepth(coord);
    float maxdiff = 0;
    for (int i = -1; i <= 1; i++) {
        for (int o = -1; o <= 1; o++) {
            float d = getDepth_int(coord + screenSizeInverse * vec2(i, o));
            maxdiff = max(maxdiff, abs(d-depth));
        }
    }
    return clamp(pow(maxdiff * 1e2 * OUTLINE_DISTANCE, 7), 0, 1);
}

vec3 vectorBlur(vec2 coord, vec2 blur, int samples) {
    if (length(blur) < screenSizeInverse.x) { return getAlbedo(coord); }

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
    vec3 color  = getAlbedo(coord);
    float depth = getDepth(coord);

    #ifdef GODRAYS

        // Start transforming sunPosition from view space to screen space
        vec3 lightPos = pickSunMoon(sunPosition, moonPosition, worldTime);
        vec4 tmp      = gbufferProjection * vec4(lightPos, 1.0);

        if (tmp.w > 0) { // If w is negative, the sun is on the opposite side of the screen (this causes bugs, I don't want that)
            // Finish screen space transformation
            vec3 sunClip      = tmp.xyz / tmp.w;
            vec2 sunScreen    = sunClip.xy * .5 + .5;

            // Create ray pointing from the current pixel to the sun
            vec2 ray          = sunScreen - coord;
            vec2 rayCorrected = vec2(ray.x, ray.y * (screenSize.y / screenSize.x)); // Aspect Ratio corrected ray for accurate exponential decay

            vec2 rayStep      = ray / GODRAY_STEPS;
            #ifndef TAA
            vec2 rayPos       = coord - (Bayer8(coord * screenSize) * rayStep);
            #else
            vec2 taa_offs     = fract(vec2(frameCounter * 0.2, -frameCounter * 0.2 - 0.5)) * 5 - 10;
            vec2 rayPos       = coord - (Bayer8(coord * screenSize + taa_offs) * rayStep);
            #endif

            float light = 1;
            for (int i = 0; i < GODRAY_STEPS; i++ ) {

                rayPos       += rayStep;

                if (isEyeInWater != 0) {
                    if (texture(depthtex1, rayPos).x != 1) { // Subtract from light when there is an occlusion
                        light    -= 1. / GODRAY_STEPS;
                    }
                } else {
                    if (texture(depthtex0, rayPos).x != 1) { // Subtract from light when there is an occlusion
                        light    -= 1. / GODRAY_STEPS;
                    }
                }

            }

            // Exponential falloff (also making it FOV independent)
            light *= exp2(-sqmag(rayCorrected) * 10 / fovScale);

            color += clamp(light * GODRAY_STRENGTH * fogColor, 0, 1); // Additive Effect
        }

    #endif


    #if FOG != 0

        // Blend between FogColor and normal color based on square distance
        vec3 viewPos    = toView(vec3(coord, depth) * 2 - 1);

        float dist      = sqmag(viewPos) * float(depth != 1);
        #if FOG == 1
        float fog       = clamp(dist * 3e-6 * FOG_AMOUNT, 0, 1);
        #else
        float fog       = clamp(dist / sq(far * 2) * FOG_AMOUNT, 0, 1);
        #endif

        if (isEyeInWater == 5) {
            color           = mix(color, (color) * fogColor, fog);
        } else {
            color           = mix(color, (color * 0.1) + fogColor, fog);
        }

    #endif

    #ifdef OUTLINE
        color = mix(color, vec3(1), depthEdge(coord) * OUTLINE_BRIGHTNESS);
    #endif
    

    #ifdef HAND_INVISIBILITY_EFFECT

        if (abs(getType(coord) - 51) < .2 && isInvisibleSmooth > 0.0001) { // Hand invisbility Effect
            float vel  = sqmag((cameraPosition - previousCameraPosition) / frameTime) * .005;

            vec2 seed1 = coord * 15 + vec2(0., frameTimeCounter * 2);
            vec2 seed2 = coord * 15 + vec2(frameTimeCounter * 2, 0.);
            vec2 noise = vec2(
                fbm(seed1, 2, 5, .05), 
                fbm(seed2, 2, 5, .05)
            );
            noise = normalize(noise - .25) * (vel + .05) * isInvisibleSmooth;

            color = vectorBlur(coord + noise, -(noise * Bayer4(coord * screenSize)), 5);
        }

    #endif

    //Pass everything forward
    FD0          = vec4(color, 1);
}