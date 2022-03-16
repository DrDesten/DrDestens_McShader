

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform sampler2D colortex4;
const bool colortex4MipmapEnabled = true;

uniform float nearInverse;

#ifdef TAA
uniform int   frameCounter;
#endif

//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////

float filteredAO(vec3 screenPos, vec2 customJitter) {
    float ao = 0;
    float wt = 0;
    float ld = linearizeDepthf(screenPos.z, nearInverse);
    for (int i = 0; i < 4; i++) {
        vec2  offs = (starOffsets[i] * screenSizeInverse) * 2 + customJitter;
        float s    = textureLod(colortex4, screenPos.xy * 0.5 + offs, 1).x;
        float sd   = getDepth(offs * (3/2) + screenPos.xy);

        float w    = max(abs(ld - linearizeDepthf(sd, nearInverse)) * -2.0 + 1, 0.00001);
        wt        += w;
        ao         = s * w + ao;
    }
    ao /= wt;
    return ao;
}
float filteredAO(vec3 screenPos) {
    float ao = 0;
    float wt = 0;
    float ld = linearizeDepthf(screenPos.z, nearInverse);
    for (int i = 0; i < 4; i++) {
        vec2  offs = (starOffsets[i] * screenSizeInverse) * 2;
        float s    = textureLod(colortex4, screenPos.xy * 0.5 + offs, 1).x;
        float sd   = getDepth(offs * (3/2) + screenPos.xy);

        float w    = max(abs(ld - linearizeDepthf(sd, nearInverse)) * -2.0 + 1, 0.00001);
        wt        += w;
        ao         = s * w + ao;
    }
    ao /= wt;
    return ao;
}

float filteredAO2(vec3 screenPos) {
    ivec2 LRintPixel = ivec2(screenPos.xy * screenSize * 0.5);

    float ld = linearizeDepthf(screenPos.z, nearInverse);

    float ao = 0;
    float tw = 0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            ivec2 sco  = ivec2(x,y) + LRintPixel;

            float sd = texelFetch(depthtex0, sco * 2 + 1, 0).x;
            float sld = linearizeDepthf(sd, nearInverse);
            float w = exp(sq(ld - sld) * -10);

            ao += texelFetch(colortex4, sco, 0).x * w;
            tw += w;
        }
    }

    return ao / tw;
}

/* DRAWBUFFERS:0 */
void main() {
    vec3  color = getAlbedo(coord);
    float type  = getType(coord);

    if (type != 50 && type != 51) {
        vec3 screenPos = vec3(coord, getDepth(coord));

        #ifdef TAA
        vec2  jitter = TAAOffsets[int(mod(Bayer4(gl_FragCoord.xy) * (16. * PHI_INV) + frameCounter, 9))] * screenSizeInverse * 8;
        float ao = filteredAO(screenPos, jitter);
        #else
        float ao = filteredAO(screenPos);
        #endif

        //ao = texture2D(colortex4, coord * 0.5).r;

        ao = pow(ao, ssao_strength);

        ao = filteredAO2(screenPos);
        //ao = filteredAO(screenPos);
        ao = pow(ao, 8);

        color   *= ao;
        //color = vec3(ao);
    }

    gl_FragData[0] = vec4(color, 1.0);
}