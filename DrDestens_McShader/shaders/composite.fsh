#version 130

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = R32F;
const int colortex2Format = RGB16;

const int colortex4Format = RGBA8; 

*/

const bool depthtex0Clear = false; 
const bool depthtex2Clear = false;


#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

#define SMOOTH_WATER_THRESHOLD 0.6                  // Angle limit for smoothing Water              [0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
#define BLUR_WATER_NORMALS

varying vec2 texcoord;

uniform float near;
uniform float far;

uniform mat4 gbufferProjection;

/*
vec3 getViewPos(vec2 coord, float pixeldepth) {
    vec3 screenPos = vec3(coord, pixeldepth);
    vec3 clipPos = screenPos * 2.0 - 1.0;
    vec4 tmp = gbufferProjectionInverse * vec4(clipPos, 1.0);
    vec3 viewPos = tmp.xyz / tmp.w;

    return viewPos;
}
*/

vec3 blurNormal(vec2 coord, vec3 pixelNormal, float amount) {

    vec3 normal = vec3(0);
    vec2 newcoord;

    for (int i = 0; i < 16; i++) {
        newcoord = (circle_blur_16[i] * amount * ((randf_01(coord) * 0.5) + 0.75)) + coord;

        vec3 sampleNormal = getNormal(newcoord);
        int isBlur = int(distance(pixelNormal, sampleNormal) < SMOOTH_WATER_THRESHOLD);

        normal += sampleNormal * isBlur;
        normal += pixelNormal * int(isBlur == 0);
    }
    return normal * 1/16;
}

/* DRAWBUFFERS:12 */

void main() {
    vec3 normal         = getNormal(texcoord);

    float depth         = getDepth(texcoord);
    float linearDepth   = linearizeDepth(depth, near, far);

    #ifdef BLUR_WATER_NORMALS
    if (getType(texcoord) == vec3(0, 0, 1)) {
        float fovScale = gbufferProjection[1][1] * 0.7299270073;

        normal = blurNormal(texcoord, normal, 0.1 * fovScale / linearDepth);
    }
    #endif

    //Pass everything forward
    
    COLORTEX_0          = vec4(linearDepth);
    COLORTEX_1          = vec4((normal * 0.5) + 0.5, 1);
}