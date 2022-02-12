//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                    DENOISE AND OUTLINE AND FOG
//////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"

#if defined TAA || defined DEPTH_OF_FIELD
#include "/lib/transform.glsl"
#endif

#ifdef TAA
uniform sampler2D colortex5;
uniform int taaIndex;
#endif

#ifdef DEPTH_OF_FIELD
#include "/lib/dof.glsl"
uniform float centerDepthSmooth;
uniform float near;
uniform float far;
#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

void neighborhoodClamp(vec2 coord, out vec3 minColor, out vec3 maxColor, float size) {
    minColor = vec3(1e35);
    maxColor = vec3(0);
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 sample = vec2(x, y) * size * screenSizeInverse + coord;
            vec3 color  = getAlbedo(sample);

            minColor = min(minColor, color);
            maxColor = max(maxColor, color);
        }
    }
}

#ifdef TAA 
/* DRAWBUFFERS:05 */
#else
/* DRAWBUFFERS:0 */
#endif

void main() {
    #ifdef TAA
        vec2 jitterCoord = coord + TAAOffsets[taaIndex] * TAA_JITTER_AMOUNT * screenSizeInverse;
        vec3 color = getAlbedo(jitterCoord);
    #else
        vec3 color = getAlbedo(coord);
    #endif

    float depth = getDepth(coord);
    float id    = getID(coord);

    #ifdef TAA 

        vec3  currentFrameColor = color;
        vec3  screenPos         = vec3(coord, depth);

        vec3  reprojectPos      = reprojectTAA(screenPos);
        
        vec4  lastFrame         = texture(colortex5, reprojectPos.xy);
        vec3  lastFrameColor    = lastFrame.rgb;

        // Anti - Ghosting
        //////////////////////////////////////////////////////////////////////

        #ifndef TAA_NOCLIP
         vec3 lowerThresh, higherThresh;
         neighborhoodClamp(coord, lowerThresh, higherThresh, 1);
         lastFrameColor = clamp(lastFrameColor, lowerThresh, higherThresh);
        #endif

        float boundsError = float(saturate(reprojectPos.xy) != reprojectPos.xy);
        float blend       = saturate(boundsError + TAA_BLEND);

        color         = mix(lastFrameColor, currentFrameColor, blend);
        vec3 TAAcolor = max(color, 0.0);

    #endif

    #ifdef DEPTH_OF_FIELD

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
    gl_FragData[0]          = vec4(color, coc);
    #ifdef TAA 
    gl_FragData[1]          = vec4(TAAcolor, 1);
    #endif
}