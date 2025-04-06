/*

const int colortex0Format = RGBA16F;        // Color / Albedo
const int colortex1Format = RG8;            // Normals
const int colortex2Format = R8;             // blockId
const int colortex3Format = RGB8;           // Lightmap (2), AO

const int colortex4Format = R11F_G11F_B10F; // DOF 2 (DOF1 is colortex0) & Bloom
const int colortex5Format = RGB16F;         // TAA
const int colortex6Format = RGBA8;          // Weather

const int colortex7Format = RGBA8;          // PBR: Roughness, Reflectance, Height, Emission

*/


const bool colortex0Clear      = true;
const bool colortex1Clear      = false;
//const bool colortex2Clear      = false;
const bool colortex3Clear      = false;
const bool colortex4Clear      = false;
const bool colortex5Clear      = false;

const vec4 colortex0ClearColor = vec4(0,0,0,1);
const vec4 colortex2ClearColor = vec4(0,0,0,0);
const vec4 colortex3ClearColor = vec4(0,1,1,0);
const vec4 colortex4ClearColor = vec4(.5, .5, .5, 1);

const float eyeBrightnessHalflife = 1.0;

const float ambientOcclusionLevel = 1.00; // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
