

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform sampler2D colortex4;
const bool colortex4MipmapEnabled = true;

uniform float nearInverse;

//////////////////////////////////////////////////////////////////////////////
//                     SCREEN SPACE AMBIENT OCCLUSION
//////////////////////////////////////////////////////////////////////////////

float filteredAO(vec3 screenPos) {
    float ao = 0;
    float wt = 0;
    float ld = linearizeDepthf(screenPos.z, nearInverse);
    for (int i = 0; i < 4; i++) {
        vec2  offs = starOffsets[i] * screenSizeInverse * 2;
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
    float ao    = filteredAO(vec3(coord, getDepth(coord)));

    color *= ao;

    gl_FragData[0] = vec4(color, 1.0);
}