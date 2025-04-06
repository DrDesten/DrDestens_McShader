/*

const int colortex0Format = RGBA16F;        // Color / Albedo
const int colortex1Format = RG8;            // Normals
const int colortex2Format = R8;             // blockId
const int colortex3Format = RGB8;           // Lightmap (2), AO

const int colortex4Format = R11F_G11F_B10F; // DOF 2 (DOF1 is colortex0) & Bloom
const int colortex5Format = RGB16F;         // TAA
const int colortex6Format = RGBA8;          // Weather

const int colortex7Format = RG16;          // PBR: Roughness, Reflectance, Height, Emission

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
const float ambientOcclusionLevel = 1.00; 