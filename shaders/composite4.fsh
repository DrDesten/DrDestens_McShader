//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                    DENOISE AND OUTLINE AND FOG
//////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"
#include "/lib/dof.glsl"

uniform float centerDepthSmooth;
uniform float near;
uniform float far;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;


/* DRAWBUFFERS:0 */

void main() {
    vec3  color = getAlbedo(coord);
    float depth = getDepth(coord);
    float id    = getID(coord);

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
}