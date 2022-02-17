
/*

const int colortex0Format = RGBA16F; // Color

const int colortex1Format = RG8;           // Reflectiveness, Height (and in the future other PBR values)
const int colortex2Format = RGB8_SNORM;    // Normals

const int colortex3Format = R8;             // colortex3 = blockId
const int colortex4Format = R11F_G11F_B10F; // DOF 2 (DOF1 is colortex0)

const int colortex5Format = R11F_G11F_B10F; // TAA


*/

const bool colortex0Clear      = false;
const bool colortex1Clear      = false;
const bool colortex2Clear      = false;
//const bool colortex3Clear      = false;
//const bool colortex4Clear      = false;
const bool colortex5Clear      = false;

const vec4 colortex1ClearColor = vec4(0,1,0,1);
const vec4 colortex3ClearColor = vec4(0,0,0,0);
const vec4 colortex4ClearColor = vec4(.5, .5, .5, 1);

const float eyeBrightnessHalflife = 1.0;

const float sunPathRotation = -35;        // [-50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50]
const float ambientOcclusionLevel = 1.00; // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]


//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         REFLECTIONS AND WATER EFFECTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////

uniform sampler2D depthtex1;

uniform float frameTimeCounter;
uniform float nearInverse;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

/* DRAWBUFFERS:0 */
void main() {

    float id    = getID(ivec2(gl_FragCoord.xy));
    float depth       = getDepth(ivec2(gl_FragCoord.xy));
    float linearDepth = linearizeDepthf(depth, nearInverse);
    
    if (id == 10) {
        vec2 distort = vec2( sin( noise(coord * 3 * linearDepth) * TWO_PI + (frameTimeCounter * 2)) * 0.005 );
        coord += distort;
    }

    depth       = getDepth(coord);
    linearDepth = linearizeDepthf(depth, nearInverse);

    vec3  color = getAlbedo(coord);

    if (id == 10) {

        float transparentDepth       = texture(depthtex1, coord).r;
        float transparentLinearDepth = linearizeDepthf(transparentDepth, nearInverse);

        float absorption = exp(-abs(transparentLinearDepth - linearDepth));

        color = mix(vec3(0,0.015,0.1), color, absorption);


    }
    
    //Pass everything forward
    gl_FragData[0] = vec4(color, 1);
}