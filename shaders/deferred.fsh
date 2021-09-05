#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"

uniform float nearInverse;
uniform float aspectRatio;

uniform vec3  fogColor;

uniform int   frameCounter;

in vec2 coord;


//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////


float depthToleranceAttenuation(float depthDiff, float peak) {
    return peak - abs(depthDiff - peak);
}

float AmbientOcclusionLOW(vec3 screenPos, vec3 normal, float size) {
    vec3 viewPos           = toView(screenPos * 2 - 1);
    mat3 TBN               = arbitraryTBN(normal);

    float ditherTimesSize  = (Bayer4(screenPos.xy * screenSize) * 0.8 + 0.2) * size;
    float depthTolerance   = 0.075/-viewPos.z;

    float hits = 0;
    vec3 sample;
    for (int i = 0; i < 8; i++) {
        sample      = half_sphere_8[i] * ditherTimesSize; 
        sample.z   += 0.05;                                                       // Adding a small (5cm) z-offset to avoid clipping into the block due to precision errors
        sample      = TBN * sample;
        sample      = backToClip(sample + viewPos) * 0.5 + 0.5;                  // Converting Sample to screen space, since normals are in view space
    
        float hitDepth = getDepth_int(sample.xy);

        hits += float(sample.z > hitDepth && (sample.z - hitDepth) < depthTolerance);
    }

    hits  = -hits * 0.125 + 1;
    return sq(hits);
}

float AmbientOcclusionHIGH(vec3 screenPos, vec3 normal, float size) {
    vec3 viewPos           = toView(screenPos * 2 - 1);
    mat3 TBN               = arbitraryTBN(normal);

    float ditherTimesSize  = (Bayer4(screenPos.xy * screenSize) * 0.8 + 0.2) * size;
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
        //hits += saturate(depthToleranceAttenuation(sample.z - hitDepth, depthTolerance * 0.5) * 100) * 2;
    }

    hits  = -hits * 0.0625 + 1;
    return sq(hits);
}

vec4 AmbientOcclusionHIGH_SSGI(vec3 screenPos, vec3 normal, float size) {
    vec3 viewPos           = toView(screenPos * 2 - 1);
    mat3 TBN               = arbitraryTBN(normal);

    #ifdef TAA
     float ditherTimesSize  = (fract(Bayer16(screenPos.xy * screenSize) + frameCounter * 0.1243457) * 0.8 + 0.2) * size;
    #else
     float ditherTimesSize  = (Bayer4(screenPos.xy * screenSize) * 0.8 + 0.2) * size;
    #endif
    float sizeInverse      = 1/ditherTimesSize;

    float occlusion = 0;
    vec3  ssgi      = vec3(0);
    vec3  sample;
    for (int i = 0; i < 16; i++) {
        sample      = half_sphere_16[i] * ditherTimesSize; 
        sample.z   += 0.05;                                                       // Adding a small (5cm) z-offset to avoid clipping into the block due to precision errors
        sample      = TBN * sample;
        sample      = backToClip(sample + viewPos) * 0.5 + 0.5;                   // Converting Sample to screen space, since normals are in view space
    
        float expectDepth = linearizeDepthf(sample.z, nearInverse);
        float hitDepth    = linearizeDepthf(getDepth_int(sample.xy), nearInverse);
        float weight      = (float(hitDepth > 0.5) * 0.75 + 0.25) * saturate(depthToleranceAttenuation(expectDepth - hitDepth, 1) * 4);

        occlusion += weight;
        ssgi      += getAlbedo_int(sample.xy) * weight * sizeInverse * float(hitDepth > 0.5);
    }

    ssgi     *= 0.0625;
    ssgi      = sq(ssgi) * 0.5;
    occlusion = sq(-occlusion * 0.0625 + 1);
    return vec4(ssgi, occlusion);
}
/* vec4 AmbientOcclusionHIGH_SSGI(vec3 screenPos, vec3 normal, float size) {
    vec3 viewPos           = toView(screenPos * 2 - 1);

    float ditherTimesSize  = (Bayer4(screenPos.xy * screenSize) * 0.8 + 0.2) * size;
    float depthTolerance   = 0.075/-viewPos.z;

    //vec3 tangent           = normalize(cross(normal, vec3(0,0,1)));               //Simply Creating A orthogonal vector to the normals, actual tangent doesnt really matter
    vec3 tangent           = normalize(cross(normal, vec3(Bayer8(screenPos.xy * screenSize + vec2(3, -8)) * 2 - 1,
                                                          Bayer8(screenPos.xy * screenSize) * 2 - 1,
                                                          Bayer8(screenPos.xy * screenSize + vec2(-5, 1)) * 2 - 1 )));               //Simply Creating A orthogonal vector to the normals, actual tangent doesnt really matter
    mat3 TBN               = mat3(tangent, cross(tangent, normal), normal);

    float occlusion = 0;
    vec3  ssgi      = vec3(0);
    vec3  sample;
    for (int i = 0; i < 16; i++) {
        sample      = half_sphere_16[i] * ditherTimesSize; 
        sample.z   += 0.05;                                                       // Adding a small (5cm) z-offset to avoid clipping into the block due to precision errors
        sample      = TBN * sample;
        sample      = backToClip(sample + viewPos) * 0.5 + 0.5;                  // Converting Sample to screen space, since normals are in view space
    
        float hitDepth = getDepth_int(sample.xy);
        float hit      = float(sample.z > hitDepth && (sample.z - hitDepth) < depthTolerance);

        occlusion += hit;
        ssgi       = getAlbedo_int((sample.xy - screenPos.xy) * 2 + screenPos.xy) * hit;
    }

    occlusion  = sq(-occlusion * 0.0625 + 1);
    //ssgi      *= 0.0625;
    return vec4(ssgi, occlusion);
} */

// Spins A point around the origin (negate for full coverage)
vec2 spiralOffset(float x, float expansion) {
    float n = fract(x * expansion) * PI;
    return vec2(cos(n), sin(n)) * x;
}

// Based on BSL's AO implementation
float BSLAO(vec3 screenPos, float radius) {
    if (screenPos.z >= 1.0 || screenPos.z < 0.56) {return 1.0;};

    #ifdef TAA
    float dither = fract(Bayer8(screenPos.xy * screenSize) + (frameCounter * 0.136)) * 0.2;
    #else
    float dither = Bayer8(screenPos.xy * screenSize) * 0.2;
    #endif 
    float depth  = linearizeDepthf(screenPos.z, nearInverse);

    float size   = clamp(aspectRatio * radius * gbufferProjection[1][1] * 1/depth, 0.01, 0.2);

    float occlusion = 0.0;
    float sample    = 0.3 + dither;
    for (int i = 0; i < 4; i++) {
        vec2 offs = spiralOffset(sample + dither, 8) * size;

        for (int o = 0; o < 2; o++) {
            float sdepth = linearizeDepthf(getDepth_int(screenPos.xy + offs), nearInverse);
            occlusion   += clamp((depth - sdepth) * 4, -1, 1);
            offs         = -offs;
        }

        sample += 0.2;
    }
    occlusion *= 0.125;

    return clamp(1 - occlusion, 0, 1);
}

/* DRAWBUFFERS:0 */
void main() {
    vec3  color       = getAlbedo(coord);
    float depth       = getDepth(coord);
    float type        = getType(coord);


    //////////////////////////////////////////////////////////
    //                  SSAO
    //////////////////////////////////////////////////////////

    #ifdef SCREEN_SPACE_AMBIENT_OCCLUSION

        if (abs(type - 50) > .2 && depth != 1) {

            #if   SSAO_QUALITY == 1

                //vec3 normal = getNormal(coord);
                //color      *= AmbientOcclusionLOW(vec3(coord, depth), normal, 0.5) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);
                color      *= BSLAO(vec3(coord, depth), 0.1) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);

            #elif SSAO_QUALITY == 2

                vec3 normal = getNormal(coord);

                #ifdef SCREEN_SPACE_GLOBAL_ILLUMINATION
                    vec4 ssao_gi = AmbientOcclusionHIGH_SSGI(vec3(coord, depth), normal, 1);
                    color       += ssao_gi.rgb;
                    color       *= ssao_gi.a * SSAO_STRENGTH + (1 - SSAO_STRENGTH);
                #else
                    color       *= AmbientOcclusionHIGH(vec3(coord, depth), normal, 0.5) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);
                #endif

            #endif
            
        }

    #endif

    //color = 1 - vec3(AmbientOcclusion(Bayer4(coord * screenSize)));
    //color = vec3(BSLAO(vec3(coord, depth), 0.1));

    FD0 = vec4(color, 1.0);
}