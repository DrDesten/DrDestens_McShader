

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                      MOTION BLUR AND BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"
#include "/lib/dof.glsl"

uniform sampler2D colortex4;

const bool colortex0MipmapEnabled = true; //Enabling Mipmapping
const bool colortex4MipmapEnabled = true; //Enabling Mipmapping

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float centerDepthSmooth;

uniform float near;
uniform float far;
uniform float aspectRatio;


/* DRAWBUFFERS:0 */
void main() {
    float type  = getID(coord);

    float depth        = getDepth(coord);
    float linearDepth  = linearizeDepth(depth, near, far);
    float clinearDepth = linearizeDepth(centerDepthSmooth, near, far);

    float coc  = getCoC(linearDepth, clinearDepth, fovScale * DOF_STRENGTH);
    vec2  cocv = aspectCorrect(coc, aspectRatio);
    
    float lod = log2((coc * screenSize.x) * (DOF_DOWNSAMPLING/dof_pass_samples) + 1);

    vec2 blurVec1 = vec2( cos(PI / 6.), sin(PI / 6.) ) * cocv;
    vec3 color1   = hexBokehVectorBlur(colortex0, coord, blurVec1, dof_pass_samples, 1./dof_pass_samples, lod, aspectRatio);

    vec2 blurVec2 = vec2( cos(PI / (-5./6.)), sin(PI / (-5./6.)) ) * cocv;
    vec3 color2   = hexBokehVectorBlur(colortex4, coord, blurVec2, dof_pass_samples, 1./dof_pass_samples, lod, aspectRatio, colortex0);

    vec3 color = (color1 + color2) * 0.5;

    //color = texture(colortex0, coord).rgb;

    //color = vec3(float(linearDepth > clinearDepth));

    if (type == 51) {
        color = getAlbedo(coord);
    }

    //Pass everything forward
    gl_FragData[0] = vec4(color, 1);
}