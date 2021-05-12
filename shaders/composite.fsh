#version 130



/*
const int colortex0Format = RGB16F;
const int colortex1Format = R32F;
const int colortex2Format = RGB16_SNORM;

const int colortex4Format = R16F; // Colortex4 = blockId
const int colortex5Format = RGB8; // Colortex5 = bloom
*/


#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

#define SMOOTH_WATER_THRESHOLD 0.4                  // Angle limit for smoothing Water              [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define BLUR_WATER_NORMALS

in vec2 coord;

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

        // Branchless if (isBlur) { += sampleNormal } else { += pixelNormal }
        normal += sampleNormal * isBlur;
        normal += pixelNormal * int(isBlur == 0);
    }
    return normal * 0.0625;
}

/* DRAWBUFFERS:12 */

void main() {
    vec3 normal         = getNormal(coord);
    float linearDepth   = linearizeDepth(getDepth(coord), near, far);

    #ifdef BLUR_WATER_NORMALS

        if (getType(coord) == 1) {
            float fovScale = gbufferProjection[1][1];
            normal = blurNormal(coord, normal, 0.07299270073 * fovScale / linearDepth);
        }

    #endif

    //Pass everything forward
    FD0          = vec4(linearDepth);
    FD1          = vec4(normal, 1);
}