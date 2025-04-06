#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/kernels.glsl"
#include "/core/transform.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/normal.glsl"
#include "/lib/composite/id.glsl"
#include "/lib/composite/lightmap.glsl"

uniform float nearInverse;
uniform float aspectRatio;

uniform int   frameCounter;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform sampler2D colortex4;
const bool colortex4MipmapEnabled = true; //Enabling Mipmapping

//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////

float linearPeakAttenuation(float depthDiff, float slope){
    float f = depthDiff * slope;
    float g = -(depthDiff - (1 + 1/slope));
    return saturate(min(g, f));
}
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

// Old function, keeping it for reference
/* float AmbientOcclusionLOW(vec3 screenPos, vec3 normal, float size) {
    vec3 viewPos           = toView(screenPos * 2 - 1);
    mat3 TBN               = arbitraryTBN(normal);

    #ifdef TAA
     float ditherTimesSize  = (fract(Bayer4(screenPos.xy * screenSize) + (frameCounter * 0.136)) * 0.85 + 0.15) * size;
    #else
     float ditherTimesSize  = (Bayer4(screenPos.xy * screenSize) * 0.85 + 0.15) * size;
    #endif
    float depthTolerance   = 0.075/-viewPos.z;

    float hits = 0;
    vec3 scoord;
    for (int i = 0; i < 8; i++) {
        scoord      = half_sphere_8[i] * ditherTimesSize; 
        scoord.z   += 0.05;                                                       // Adding a small (5cm) z-offset to avoid clipping into the block due to precision errors
        scoord      = TBN * scoord;
        scoord      = backToClip(scoord + viewPos) * 0.5 + 0.5;                  // Converting Sample to screen space, since normals are in view space
    
        float hitDepth = getDepth(scoord.xy);

        hits += float(scoord.z > hitDepth && (scoord.z - hitDepth) < depthTolerance);
    }

    hits  = -hits * 0.125 + 1;
    return sq(hits);
} */
float AmbientOcclusionLOW(vec3 screenPos, vec3 normal, float size) {
    vec3 viewPos      = toView(screenPos * 2 - 1);
    float linearDepth = linearizeDepthf(screenPos.z, nearInverse);

    #ifdef TAA
     float ditherTimesSize  = (fract(Bayer4(screenPos.xy * screenSize) + (frameCounter * PHI_INV)) * 0.9 + 0.1) * size;
    #else
     float ditherTimesSize  = (Bayer4(screenPos.xy * screenSize) * 0.85 + 0.15) * size;
    #endif

    float hits = 0;
    for (int i = 0; i < 8; i++) {

        vec3 scoord = vogel_sphere_8[i] * ditherTimesSize;
        scoord     *= sign(dot(normal, scoord));                        // Inverts the sample position if its pointing towards the surface (thus being within it). Much more efficient than using a tbn
        scoord     += normal * 0.05;                                    // Adding a small offset away from the surface to avoid self-occlusion and SSAO acne
        scoord      = backToClip(scoord + viewPos) * 0.5 + 0.5;

        float hitDepth = getDepth(scoord.xy);

        float depthDiff = saturate(scoord.z - hitDepth) * linearDepth;
        hits += linearAttenuation(depthDiff, size * 0.6, 3) * float(scoord.z > hitDepth);
    }

    hits  = saturate(-hits * 0.125 + 1.125);
    return sqsq(hits);
}

float AmbientOcclusionHIGH(vec3 screenPos, vec3 normal, float size) {
    vec3  viewPos     = toView(screenPos * 2 - 1);
    float linearDepth = linearizeDepthf(screenPos.z, nearInverse);

    #ifdef TAA
     float ditherTimesSize  = (fract(Bayer4(screenPos.xy * screenSize) + (frameCounter * 0.136)) * 0.85 + 0.15) * size;
    #else
     float ditherTimesSize  = (Bayer4(screenPos.xy * screenSize) * 0.85 + 0.15) * size;
    #endif
    float depthTolerance   = 0.075/-viewPos.z;

    float hits = 0;
    for (int i = 0; i < 16; i++) {

        vec3 scoord = vogel_sphere_16[i] * ditherTimesSize;
        scoord     *= sign(dot(normal, scoord));                   // Inverts the sample position if its pointing towards the surface (thus being within it). Much more efficient than using a tbn
        scoord     += normal * 0.025;                              // Adding a small offset away from the surface to avoid self-occlusion and SSAO acne
        scoord      = backToClip(scoord + viewPos) * 0.5 + 0.5;

        float hitDepth = getDepth(scoord.xy);

        float depthDiff = saturate(scoord.z - hitDepth) * linearDepth;
        hits += linearAttenuation(depthDiff, size * 0.5, 3) * float(scoord.z > hitDepth);
    }

    hits  = -hits * 0.0625 + 1;
    return sqsq(hits);
}

vec3 HBAO_like(vec3 screenPos, vec3 screenNormal, float radius) {
    float dither = Bayer4(gl_FragCoord.xy);

    float dirDither = dither * TWO_PI + (frameCounter);
    vec2  dir       = vec2(sin(dirDither), cos(dirDither)) * radius;

    float ao = 0;
    for (int i = 0; i < 4; i++) {
        vec2 sdir = dir * i;

        float sd1 = getDepth(screenPos.xy + sdir);
        float sd2 = getDepth(screenPos.xy - sdir);

        vec3 s1 = normalize(vec3( sdir, sd1 - screenPos.z));
        vec3 s2 = normalize(vec3(-sdir, sd2 - screenPos.z));

        float angle1 = saturate(-dot(s1, screenNormal));
        float angle2 = saturate(-dot(s2, screenNormal));
        float occlusion = angle1 + angle2;

        ao += occlusion * 0.125;
    }

    return vec3(ao * 1.05 - 0.05);
}


// Really Fast™ SSAO
float SSAO(vec3 screenPos, float radius) {
    #ifdef TAA
     float dither = fract(Bayer8(screenPos.xy * screenSize) + (frameCounter * PHI_INV)) * 0.2;
    #else
     float dither = Bayer8(screenPos.xy * screenSize) * 0.2;
    #endif

    float radZ   = radius * linearizeDepthfDivisor(screenPos.z, nearInverse);
    float dscale = 20 / radZ;
    vec2  rad    = vec2(radZ * fovScale, radZ * fovScale * aspectRatio);

    float scoord      = 0.2 + dither;
    float increment   = radius * PHI_INV;
    float occlusion   = 0.0;
    for (int i = 0; i < 8; i++) {

        vec2 offs = spiralOffset_full(scoord, 7.5 * PHI_INV) * rad;

        float sdepth = getDepth(screenPos.xy + offs);
        float diff   = screenPos.z - sdepth;

        occlusion   += clamp(diff * dscale, -1, 1) * cubicAttenuation2(diff, radZ);

        scoord += increment;

    }

    occlusion = sqsq(1 - saturate(occlusion * 0.125));
    return occlusion;
}

/* DRAWBUFFERS:3 */
layout(location = 0) out vec4 FragOut0;

void main() {
    vec3 lightmap = getLightmapData(ivec2(gl_FragCoord.xy));

#ifdef SCREEN_SPACE_AMBIENT_OCCLUSION

    float depth = getDepth(ivec2(gl_FragCoord.xy));
    float id    = getID(ivec2(gl_FragCoord.xy));

    vec3 screenPos = vec3(coord, depth);

    if ((id < 50 || id > 52) && depth != 1) {

        #if   SSAO_QUALITY == 1

            lightmap.z *= SSAO(vec3(coord, depth), 0.15) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);

        #elif SSAO_QUALITY == 2

            vec3 normal = getNormal(coord);
            lightmap.z *= AmbientOcclusionLOW(vec3(coord, depth), normal, 0.375) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);

        #elif SSAO_QUALITY == 3

            vec3 normal = getNormal(coord);
            lightmap.z *= AmbientOcclusionHIGH(vec3(coord, depth), normal, 0.375) * SSAO_STRENGTH + (1 - SSAO_STRENGTH);

        #endif
        
    }

#endif

    FragOut0 = vec4(lightmap, 1);
}