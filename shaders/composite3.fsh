
/*

const int colortex0Format = R11F_G11F_B10F; // Albedo

const int colortex1Format = RGB8_SNORM;     // Normals
const int colortex2Format = RGB8;           // Lightmap + AO
const int colortex3Format = R8;             // ID (+ Masks)

const int colortex4Format = RGBA8;          // PBR: Reflectiveness (and Metals), Emissiveness, Roughness, SSS
const int colortex5Format = R8;             // PBR: Height

const int colortex7Format = RGB8;           // Bloom, SSAO
const int colortex8Format = R11F_G11F_B10F; // TAA

*/

/* BUFFERSTRUCTURE /
Col0 = Albedo
Col1 = Normals
Col2 = Lightmap
Col3 = ID (+ Masks)

Col4 = PBR: Reflectiveness+Metals, Emissive, Smoothness, SSS
Col5 = PBR: Height, AO
//////////////////*/

const bool colortex0Clear = false;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = false;
const bool colortex4Clear = false;
const bool colortex5Clear = false;

const vec4 colortex1ClearColor = vec4(0);

const float eyeBrightnessHalflife = 1.0;

const float sunPathRotation = -35; // [-50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50]


#include "/lib/settings.glsl"
#include "/lib/kernels.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

/* DRAWBUFFERS:0 */
void main() {
    vec3  color  = getAlbedo(ivec2(gl_FragCoord.xy));



    //Pass everything forward
    gl_FragData[0] = vec4(color, 1);
}