

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         DEPTH OF FIELD
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"

uniform float centerDepthSmooth;
const float   centerDepthHalflife = 1.5;

const bool    colortex0MipmapEnabled = true; //Enabling Mipmapping

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float near;
uniform float far;
uniform float aspectRatio;

vec3 chromaticAberrationTint(vec2 relPos) {
    float chromAbb     = relPos.x * chromaticAberrationDoF + 0.5;
    vec3  chromAbbTint = vec3(chromAbb, 0.75 - abs(chromAbb - 0.5), 1 - chromAbb) * 2;
    return chromAbbTint;
}

#define PLANE_DIST 5e-3
float realCoC(float linearDepth, float focusLinearDepth) {
    float focalLength = 1 / ((1/focusLinearDepth) + (1/PLANE_DIST));

    float zaehler = focalLength * (focusLinearDepth - linearDepth);
    float nenner  = linearDepth * (focusLinearDepth - focalLength);
    return abs(zaehler / nenner);
}

vec3 hexBokehVectorBlur(sampler2D tex, vec2 coord, vec2 vector, int samples, float samplesInv) {
    vec3 col      = vec3(0);
    vec2 blurStep = vector * samplesInv;
    vec2 sample   = blurStep * 0.5 + coord;

    for (int i = 0; i < samples; i++) {
        col    += texture(tex, sample).rgb;
        sample += blurStep;
    }

    return col * samplesInv;
}

/* DRAWBUFFERS:45 */

void main() {
    float depth = texture(depthtex0, coord).r;

    float linearDepth   = linearizeDepth(depth, near, far);
    float clinearDepth  = linearizeDepth(centerDepthSmooth, near, far);

    float Coc = realCoC(linearDepth, clinearDepth) * fovScale * DOF_STRENGTH;
    Coc = 100;

    vec2 blurVec1 = vec2(0, -Coc) * screenSizeInverse;
    vec3 color1   = hexBokehVectorBlur(colortex0, coord, blurVec1, 10, 1./10);

    vec2 blurVec2 = vec2( cos(PI / 6.), sin(PI / 6.) ) * screenSizeInverse * Coc;
    vec3 color2   = hexBokehVectorBlur(colortex0, coord, blurVec2, 10, 1./10);


    //Pass everything forward
    gl_FragData[0]          = vec4(color1,  1);
    gl_FragData[1]          = vec4((color1 + color2) * 0.5,  1);
}
