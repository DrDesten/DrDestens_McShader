

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         DEPTH OF FIELD
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"
#include "/lib/dof.glsl"

uniform float centerDepthSmooth;
const float   centerDepthHalflife = 1.5; // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 6.0 6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8 6.9 7.0 7.1 7.2 7.3 7.4 7.5 7.6 7.7 7.8 7.9 8.0 8.1 8.2 8.3 8.4 8.5 8.6 8.7 8.8 8.9 9 9.1 9.2 9.3 9.4 9.5 9.6 9.7 9.8 9.9 10.0]

const bool    colortex0MipmapEnabled = true; //Enabling Mipmapping

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float near;
uniform float far;
uniform float aspectRatio;

/* DRAWBUFFERS:04 */

void main() {

    #ifdef DEPTH_OF_FIELD

        float coc  = texture(colortex0, coord).a; // Reading the CoC from composite4 instead of recalculating
        vec2  cocv = aspectCorrect(coc, aspectRatio);

        float lod = log2((coc * screenSize.x) * (DOF_DOWNSAMPLING/dof_pass_samples) + 1);

        vec2 blurVec1 = vec2(0, -cocv.y);
        #ifdef DOF_SAMPLE_REJECTION
        vec3 color1   = hexBokehVectorBlur(colortex0, coord, blurVec1, dof_pass_samples, 1./dof_pass_samples, lod, aspectRatio);
        #else
        vec3 color1   = hexBokehVectorBlur_noReject(colortex0, coord, blurVec1, dof_pass_samples, 1./dof_pass_samples, lod);
        #endif

        vec2 blurVec2 = vec2( cos(PI / 6.), sin(PI / 6.) ) * cocv;
        #ifdef DOF_SAMPLE_REJECTION
        vec3 color2   = hexBokehVectorBlur(colortex0, coord, blurVec2, dof_pass_samples, 1./dof_pass_samples, lod, aspectRatio);
        #else
        vec3 color2   = hexBokehVectorBlur_noReject(colortex0, coord, blurVec2, dof_pass_samples, 1./dof_pass_samples, lod);
        #endif

    #else

        vec3 color1, color2 = vec3(0);
        float coc = 1.0;
        discard;

    #endif

    //Pass everything forward
    gl_FragData[0]          = vec4(color1,  coc);
    gl_FragData[1]          = vec4(color1 + color2,  1);
}
