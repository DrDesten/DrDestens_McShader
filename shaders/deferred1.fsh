

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

/* DRAWBUFFERS:0 */
void main() {
    vec3  color = getAlbedo(coord);
    float type  = getType(coord);

    if (type != 50 && type != 51) {
        #ifdef TAA
        vec2  jitter = TAAOffsets[int(mod(Bayer4(gl_FragCoord.xy) * (16. * PHI_INV) + frameCounter, 9))] * screenSizeInverse * 8;
        float ao = filteredAO(vec3(coord, getDepth(coord)), jitter);
        #else
        float ao = filteredAO(vec3(coord, getDepth(coord)));
        #endif

        ao = pow(ao, ssao_strength);

        color   *= ao;
        //color = vec3(ao);
    }

    gl_FragData[0] = vec4(color, 1.0);
}