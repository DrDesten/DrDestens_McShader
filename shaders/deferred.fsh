#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/lighting_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float nearInverse;
uniform float aspectRatio;

float cubicAttenuation2(float depthDiff, float cutoff) {
    depthDiff = min(cutoff, depthDiff);
    float tmp = (depthDiff - cutoff) / cutoff;
    return saturate(tmp * tmp);
}

// Really Fast™ SSAO
float SSAO(vec3 screenPos, float radius) {
    if (screenPos.z >= 1.0) { return 1.0; };

    #ifdef TAA
     float dither = fract(ign(screenPos.xy * screenSize) + (frameCounter * PHI_INV)) * 0.2;
    #else
     float dither = ign(screenPos.xy * screenSize) * 0.2;
    #endif

    float radZ   = radius * linearizeDepthfDivisor(screenPos.z, nearInverse);
    radZ         = clamp(radZ, 0.01, 0.15);
    vec2  rad    = vec2(radZ * fovScale, radZ * fovScale * aspectRatio);
    float dscale = 20 / radZ;

    float sample      = 0.2 + dither;
    float increment   = radius * PHI_INV;
    float occlusion   = 0.0;
    for (int i = 0; i < 8; i++) {

        vec2 offs = spiralOffset_full(sample, 4.5) * rad;

        float sdepth = getDepth(screenPos.xy + offs);
        float diff   = screenPos.z - sdepth;

        occlusion   += clamp(diff * dscale, -1, 1) * cubicAttenuation2(diff, radZ);

        sample += increment;

    }

    occlusion = sq(1 - saturate(occlusion * 0.125));

    return occlusion;
}

/* DRAWBUFFERS:7 */
void main() {
    float ao = SSAO(vec3(coord,getDepth(coord)), 0.3);


    gl_FragData[0] = vec4(ao);
}