

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                      MOTION BLUR AND BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"
#include "/lib/dof.glsl"

#ifdef DEPTH_OF_FIELD
uniform sampler2D colortex4;
const bool colortex0MipmapEnabled = true; //Enabling Mipmapping
const bool colortex4MipmapEnabled = true; //Enabling Mipmapping
#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float centerDepthSmooth;

uniform float near;
uniform float far;
uniform float aspectRatio;


/* DRAWBUFFERS:0 */
void main() {
    
    #ifdef DEPTH_OF_FIELD

        float coc  = texture(colortex0, coord).a; // Reading the CoC from composite4 instead of recalculating
        vec2  cocv = aspectCorrect(coc, aspectRatio);
        
        float lod = log2((coc * screenSize.x) * (DOF_DOWNSAMPLING/dof_pass_samples) + 1);

        vec2 blurVec1 = vec2( cos(PI / 6.), sin(PI / 6.) ) * cocv;
        #ifdef DOF_SAMPLE_REJECTION
        vec3 color1   = hexBokehVectorBlur(colortex0, coord, blurVec1, dof_pass_samples, 1./dof_pass_samples, lod, aspectRatio);
        #else
        vec3 color1   = hexBokehVectorBlur_noReject(colortex0, coord, blurVec1, dof_pass_samples, 1./dof_pass_samples, lod);
        #endif

        vec2 blurVec2 = vec2( cos(PI / (-5./6.)), sin(PI / (-5./6.)) ) * cocv;
        #ifdef DOF_SAMPLE_REJECTION
        vec3 color2   = hexBokehVectorBlur(colortex4, coord, blurVec2, dof_pass_samples, 1./dof_pass_samples, lod, aspectRatio, colortex0);
        #else
        vec3 color2   = hexBokehVectorBlur_noReject(colortex4, coord, blurVec2, dof_pass_samples, 1./dof_pass_samples, lod);
        #endif

        vec3 color = (color1 + color2) * (1./3);

    #else

        vec3 color = vec3(0);
        discard;

    #endif

    //Pass everything forward
    gl_FragData[0] = vec4(color, 1);
}