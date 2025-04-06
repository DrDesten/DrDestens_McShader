//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                    DENOISE AND OUTLINE AND FOG
//////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/normal.glsl"
#include "/lib/composite/id.glsl"
#include "/core/kernels.glsl"

#if defined TAA || defined DEPTH_OF_FIELD
#include "/core/transform.glsl"
#endif

#ifdef TAA
 uniform sampler2D colortex5;
 uniform vec2 taaOffset;
#endif

#ifdef DEPTH_OF_FIELD
#include "/lib/dof.glsl"
uniform float centerDepthSmooth;
uniform float near;
uniform float far;
#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse;


vec3 clipAABB(vec3 color, vec3 minAABB, vec3 maxAABB) {
    vec3 p_clip = 0.5 * (maxAABB + minAABB);
    vec3 e_clip = 0.5 * (maxAABB - minAABB);

    vec3  v_clip  = color - p_clip;
    vec3  v_unit  = v_clip.xyz / e_clip;
    vec3  a_unit  = abs(v_unit);
    float ma_unit = max(a_unit.x, max(a_unit.y, a_unit.z));

    if (ma_unit > 1.0)
        return p_clip + v_clip / ma_unit;
    else
        return color; // point inside aabb
}

vec3 neighborhoodClamp(ivec2 icoord, vec3 historyColor, out vec3 sourceColorOut) {
    vec3 mins = vec3(1e35);
    vec3 maxs = vec3(0);
    vec3 m1 = vec3(0);
    vec3 m2 = vec3(0);

    vec2 jitterOffset = taaOffset * TAA_JITTER_AMOUNT * screenSize;
    vec3 sourceColor  = vec3(0);
    vec3 sourceWeight = vec3(0);

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            float sweight = sincWindowed(x - jitterOffset.x) * sincWindowed(y - jitterOffset.y);
            ivec2 scoord  = icoord + ivec2(x, y);
            vec3  scol    = getAlbedo(scoord);

            sourceColor  += scol * sweight;
            sourceWeight += sweight;

            mins = min(mins, scol);
            maxs = max(maxs, scol);
            m1  += scol;
            m2  += sq(scol);
        }
    }

    sourceColor /= sourceWeight;
    sourceColorOut = sourceColor;

    vec3 mu    = m1 * (1./9);
    vec3 sigma = sqrt(abs(m2 * (1./9) - sq(mu)));
    vec3 minc  = mu - sigma * 0.75;
    vec3 maxc  = mu + sigma * 0.75;

    historyColor = clamp(historyColor, mins, maxs);
    historyColor = clipAABB(historyColor, minc, maxc);

    return historyColor;
}

#ifdef TAA 
/* DRAWBUFFERS:05 */
#else
/* DRAWBUFFERS:0 */
#endif
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;

void main() {
    #ifdef TAA
        vec2  jitterOffset = taaOffset * TAA_JITTER_AMOUNT;
        vec3  color        = getAlbedo(coord + jitterOffset);
        float depth        = getDepth(coord);

        vec3  sourceColor  = color;
        vec3  screenPos    = vec3(coord, depth);
        vec3  reprojectPos = reprojectTAA(screenPos);
        vec4  lastFrame    = texture(colortex5, reprojectPos.xy);

        // Anti - Ghosting
        //////////////////////////////////////////////////////////////////////

        vec3  historyColor  = lastFrame.rgb;
        float sourceWeight  = TAA_BLEND;
        float historyWeight = 1 - sourceWeight;

        historyWeight *= float(saturate(reprojectPos.xy) == reprojectPos.xy);

        #ifndef TAA_NOCLIP

        historyColor = neighborhoodClamp(ivec2(gl_FragCoord.xy), historyColor, sourceColor);

        #endif

        color         = mix(sourceColor, historyColor, historyWeight);
        vec3 TAAcolor = max(color, 0.0);

    #else 

        vec3  color = getAlbedo(coord);
        float depth = getDepth(coord);

    #endif

    #ifdef DEPTH_OF_FIELD

        float id    = getID(coord);

        // Store CoC in the alpha channel for DOF pass
        float linearDepth  = linearizeDepth(depth, near, far);
        float clinearDepth = linearizeDepth(centerDepthSmooth, near, far);

        #ifdef DOF_FAR_BLUR_ONLY
        float coc          = saturate(-getCoC_sign(linearDepth, clinearDepth, fovScale * DOF_STRENGTH));
        #else
        float coc          = getCoC(linearDepth, clinearDepth, fovScale * DOF_STRENGTH);
        #endif

        if (id == 51) coc = 0; // Exclude Hand from DÖF

        coc = min(coc, DOF_MAXSIZE);

    #else 
        const float coc = 1.0;
    #endif

    //Pass everything forward
    FragOut0 = vec4(color, coc);
    #ifdef TAA 
    FragOut1 = vec4(TAAcolor, 1);
    #endif
}