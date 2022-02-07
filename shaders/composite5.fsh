

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
const float   centerDepthHalflife = 5;

const bool    colortex0MipmapEnabled = true; //Enabling Mipmapping

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float near;
uniform float far;
uniform float aspectRatio;

/* DRAWBUFFERS:04 */

void main() {
    /* float type  = getID(coord);


    float depth = texture(depthtex0, coord).r;

    float linearDepth   = linearizeDepth(depth, near, far);
    float clinearDepth  = linearizeDepth(centerDepthSmooth, near, far);

    float coc  = getCoC(linearDepth, clinearDepth, fovScale * DOF_STRENGTH); */
    
    float coc = texture(colortex0, coord).a;
    vec2  cocv = aspectCorrect(coc, aspectRatio);

    float lod = log2((coc * screenSize.x) * (DOF_DOWNSAMPLING/dof_pass_samples) + 1);

    vec2 blurVec1 = vec2(0, -cocv.y);
    //vec3 color1   = hexBokehVectorBlur(colortex0, coord, blurVec1, dof_pass_samples, 1./dof_pass_samples, lod);
    vec3 color1   = hexBokehVectorBlur(colortex0, coord, blurVec1, dof_pass_samples, 1./dof_pass_samples, lod, aspectRatio);

    vec2 blurVec2 = vec2( cos(PI / 6.), sin(PI / 6.) ) * cocv;
    //vec3 color2   = hexBokehVectorBlur(colortex0, coord, blurVec2, dof_pass_samples, 1./dof_pass_samples, lod);
    vec3 color2   = hexBokehVectorBlur(colortex0, coord, blurVec2, dof_pass_samples, 1./dof_pass_samples, lod, aspectRatio);
    

    /* if (type == 51) {
        color1 = getAlbedo(coord);
    } */

    //Pass everything forward
    gl_FragData[0]          = vec4(color1,  coc);
    gl_FragData[1]          = vec4(color1 + color2,  1);
}
