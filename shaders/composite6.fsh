

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                      MOTION BLUR AND BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"

uniform sampler2D colortex4;
uniform sampler2D colortex5;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float centerDepthSmooth;

uniform float near;
uniform float far;
uniform float aspectRatio;

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

/* DRAWBUFFERS:0 */
void main() {
    /* vec3 color1 = texture(colortex4, coord).rgb;
    vec3 color2 = texture(colortex5, coord).rgb;

    vec3 color = color1;
    if (coord.x > 0.5) color = color2;

    color = mix(color, texture(colortex0, coord).rgb, 0.2);
    */

    float depth = texture(depthtex0, coord).r;

    float linearDepth   = linearizeDepth(depth, near, far);
    float clinearDepth  = linearizeDepth(centerDepthSmooth, near, far);

    float Coc = realCoC(linearDepth, clinearDepth) * fovScale * DOF_STRENGTH;
    Coc = 100;

    vec2 blurVec1 = vec2( cos(PI / 6.), sin(PI / 6.) ) * screenSizeInverse * Coc;
    vec3 color1   = hexBokehVectorBlur(colortex4, coord, blurVec1, 10, 1./10);

    vec2 blurVec2 = vec2( cos(PI / 6. * 5), sin(PI / 6. * 5) ) * screenSizeInverse * Coc;
    vec3 color2   = hexBokehVectorBlur(colortex5, coord, blurVec2, 10, 1./10);

    vec3 color = (color1 + color2 * 2) * (1./3);
    
    //Pass everything forward
    gl_FragData[0]          = vec4(color, 1);
}