

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                      MOTION BLUR AND BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/transform.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/normal.glsl"
#include "/lib/composite/id.glsl"
#include "/core/kernels.glsl"
#include "/lib/dof.glsl"

#ifdef DEPTH_OF_FIELD
uniform sampler2D colortex4;
const bool colortex0MipmapEnabled = true; //Enabling Mipmapping
const bool colortex4MipmapEnabled = true; //Enabling Mipmapping

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float centerDepthSmooth;

uniform float near;
uniform float far;
uniform float aspectRatio;
#endif


/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

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
        float coc = 0;
        discard;

    #endif

    //Pass everything forward
    FragOut0 = vec4(color, coc);
}