

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"

#ifdef SCREEN_SPACE_GLOBAL_ILLUMINATION
const bool    colortex0MipmapEnabled = true; //Enabling Mipmapping
#endif

uniform float nearInverse;
uniform float aspectRatio;

uniform vec3  fogColor;

uniform int   frameCounter;

in vec2 coord;


//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////


float peakAttenuation(float depthDiff, float peak) {
    return peak - abs(depthDiff - peak);
}
float linearAttenuation(float depthDiff, float cutoff, float slope) {
    return saturate((cutoff - depthDiff) * slope);
}
float cubicAttenuation(float depthDiff, float cutoff) {
    float tmp = depthDiff / cutoff;
    return saturate(-tmp * tmp + 1);
}
float cubicAttenuation2(float depthDiff, float cutoff) {
    depthDiff = min(cutoff, depthDiff);
    float tmp = (depthDiff - cutoff) / cutoff;
    return saturate(tmp * tmp);
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
        //hits += saturate(peakAttenuation(sample.z - hitDepth, depthTolerance * 0.5) * 100) * 2;
    }

    hits  = -hits * 0.0625 + 1;
    return sq(hits);
}

vec4 AmbientOcclusionHIGH_SSGI(vec3 screenPos, vec3 normal, float size) {
    float linearDepth = linearizeDepthf(screenPos.z, nearInverse);
    float sampleSize  = size / linearDepth * fovScale;

    float ao      = 0;
    vec3  ssgi    = vec3(0);
    float dither  = fract(Bayer16(screenPos.xy * screenSize) + frameCounter * 0.1);
    float iDither = dither * 63;

    for (int i = 0; i < 16; i++) {
        int  index   = int( mod(iDither + float(i), 64) );
        vec2 sample  = blue_noise_disk[ index ] * dither * sampleSize;
        vec2 sSample = sample + screenPos.xy;

        float sampleDepth  = getDepth_int(sSample);
        float sampleDepthL = linearizeDepthf(sampleDepth, nearInverse);

        //ao += saturate(peakAttenuation(linearDepth - sampleDepthL, size));
        ao   += saturate(linearDepth - sampleDepthL);
        ssgi += texture2D(colortex0, mirrorClamp(sample * 3 + screenPos.xy), -3).rgb * saturate(1 - abs(sampleDepthL - linearDepth)) / sqmag(blue_noise_disk[index]);
    }

    ao    = 1 - (ao / 16);
    ssgi  = saturate(sq(ssgi * 0.02));
    return vec4(ssgi, ao);
}

vec4 SSAO_GI(vec3 screenPos, vec3 normal, float radius) {
    if (screenPos.z >= 1.0 || screenPos.z < 0.56) { return vec4(0,0,0,1.0); };

    float dither = Bayer8(screenPos.xy * screenSize) * 0.2;
    float ldepth = linearizeDepthf(screenPos.z, nearInverse);

    float radZ   = (radius / ldepth) * 0.5;
    vec2  rad    = vec2(radZ * fovScale, radZ * fovScale * aspectRatio);
    float dscale = 4 / radZ;

    float sample      = 0.2 + dither;
    float increment   = radius * 0.125;
    float occlusion   = 0.0;
    vec3  gi = vec3(0);
    for (int i = 0; i < 16; i++) {

        vec2 offs   = spiralOffset_full(sample, 4.5) * rad;
        vec2 sCoord = screenPos.xy + offs;

        float sdepth = getDepth_int(sCoord);
        float diff   = screenPos.z - sdepth;

        occlusion   += clamp(diff * dscale, -1, 1) * cubicAttenuation2(diff, radZ);
        
        if (diff < 0 /* && mod(float(i), 2.0) == 0 */) { // Hit
            vec3 albedo  = getAlbedo_int(sCoord);

            float lightStrength = cubicAttenuation2(diff, radZ);
            gi += albedo * lightStrength;
        }

        sample += increment;

    }

    occlusion = sq(1 - saturate(occlusion / 16));
    gi /= 16;

    return vec4(gi, occlusion);
}

// Really Fast™ SSAO
float SSAO(vec3 screenPos, float radius) {
    if (screenPos.z >= 1.0 || screenPos.z < 0.56) { return 1.0; };

    #ifdef TAA
     float dither = fract(Bayer8(screenPos.xy * screenSize) + (frameCounter * 0.136)) * 0.2;
    #else
     float dither = Bayer8(screenPos.xy * screenSize) * 0.2;
    #endif
    float ldepth = linearizeDepthf(screenPos.z, nearInverse);

    float radZ   = (radius / ldepth) * 0.5;
    vec2  rad    = vec2(radZ * fovScale, radZ * fovScale * aspectRatio);
    float dscale = 8 / radZ;

    float sample      = 0.2 + dither;
    float increment   = radius * 0.125;
    float occlusion   = 0.0;
    for (int i = 0; i < 8; i++) {

        vec2 offs = spiralOffset_full(sample, 4.5) * rad;

        float sdepth = getDepth_int(screenPos.xy + offs);
        float diff   = screenPos.z - sdepth;

        occlusion   += clamp(diff * dscale, -1, 1) * cubicAttenuation2(diff, radZ);

        sample += increment;

    }

    occlusion = sq(1 - saturate(occlusion * 0.125));

    return occlusion;
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

    float size   = clamp(aspectRatio * radius * gbufferProjection[1][1] * 1/depth, 0.001, 0.2);

    float occlusion = 0.0;
    float sample    = 0.3 + dither;
    for (int i = 0; i < 4; i++) {
        vec2 offs = spiralOffset(sample, 8) * size;

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
                //color      *= BSLAO(vec3(coord, depth), 0.1) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);
                color        *= SSAO(vec3(coord, depth), 0.5) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);

            #elif SSAO_QUALITY == 2

                vec3 normal = getNormal(coord);

                #ifdef SCREEN_SPACE_GLOBAL_ILLUMINATION
                    vec4 ssao_gi = AmbientOcclusionHIGH_SSGI(vec3(coord, depth), normal, 0.5);
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

    //vec4 sgi = SSAO_GI(vec3(coord, depth), getNormal(coord), .5);
    //color = (color + sgi.rgb) * sgi.a;
    //color = vec3(SSAO(vec3(coord, depth), 1));

    FD0 = vec4(color, 1.0);
}