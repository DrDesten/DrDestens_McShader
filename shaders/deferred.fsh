#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"

uniform float near;
uniform float far;

uniform float frameTimeCounter;

in vec2 coord;


//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////


/* float AmbientOcclusionLOW(vec3 screenPos, vec3 normal, float sampleSize) {

    float size  = sampleSize / max(linearizeDepth(screenPos.z, near, far), 1) * fovScale;
    size       *= Bayer4(screenPos.xy * ScreenSize) * .9 + .1;

    float light = 0;
    for (int i = 0; i < 8; i++) {
        vec3 sampleNormal = getNormal(blue_noise_disk[i] * size + screenPos.xy);

        light    += max(dot(normal, sampleNormal), 0);
    }
    light        *= 0.125;
    light        *= light;

    return light;
} */

float depthToleranceAttenuation(float depthDiff, float peak) {
    return peak - abs(depthDiff - peak);
}
float AmbientOcclusionLOW(vec3 screenPos, float sampleSize) {

    float linearDepth = linearizeDepth(screenPos.z, near, far);
    float size        = sampleSize / linearDepth * fovScale;

    float dither      = Bayer4(screenPos.xy * ScreenSize) * 64;

    float occlusion = 0;
    for (int i = 0; i < 8; i++) {
        vec2 sample       = blue_noise_disk[ int( mod(i + dither, 64) ) ] * size + screenPos.xy;

        float sampleDepth = linearizeDepth(getDepth_int(sample), near, far);
        float occ         = (linearDepth - sampleDepth);
        occlusion        += depthToleranceAttenuation(occ, 1);
    }
    occlusion = 1 - saturate(occlusion * .3);
 
    return sq(occlusion);
}

float AmbientOcclusionHIGH(vec3 screenPos, vec3 normal, float size) {
    vec3 viewPos           = toView(screenPos * 2 - 1);

    vec3 tangent           = normalize(cross(normal, vec3(0,0,1)));               //Simply Creating A orthogonal vector to the normals, actual tangent doesnt really matter
    mat3 TBN               = mat3(tangent, cross(tangent, normal), normal);

    float ditherTimesSize  = (Bayer4(screenPos.xy * ScreenSize) * 0.8 + 0.2) * size;
    float depthTolerance   = 0.075/-viewPos.z;

    float hits = 0;
    vec3 sample;
    for (int i = 0; i < 16; i++) {
        sample      = half_sphere_16[i] * ditherTimesSize; 
        sample.z   += 0.05;                                                       // Adding a small (5cm) z-offset to avoid clipping into the block due to precision errors
        sample      = TBN * sample;
        sample      = backToClip(sample + viewPos) * 0.5 + 0.5;                  // Converting Sample to screen space, since normals are in view space
    
        float hitDepth = getDepth_int(sample.xy);

        hits += float(sample.z > hitDepth && (sample.z - hitDepth) < depthTolerance);
    }

    hits  = -hits * 0.0625 + 1;
    return sq(hits);
}


/* DRAWBUFFERS:0 */
void main() {
    vec3 color        = getAlbedo(coord);
    float depth       = getDepth(coord);
    float type        = getType(coord);

    //////////////////////////////////////////////////////////
    //                  SSAO
    //////////////////////////////////////////////////////////

    #ifdef SCREEN_SPACE_AMBIENT_OCCLUSION

        if (abs(type - 50) > .2 && depth != 1) {

            #if   SSAO_QUALITY == 1

                color *= AmbientOcclusionLOW(vec3(coord, depth), 0.15) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);

            #elif SSAO_QUALITY == 2

                vec3 normal       = getNormal(coord);
                color *= AmbientOcclusionHIGH(vec3(coord, depth), normal, 0.5) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);

            #endif
            
        }

    #endif

    FD0 = vec4(color, 1.0);
}