#define WATER_EFFECTS


// Screen Space Raytracing
/////////////////////////////////////////////////////////////////////////////////////////

#define SCREEN_SPACE_REFLECTION
//#define SSR_DEBUG

#define SSR_MODE 0                      // Screen Space Reflection Mode                 [0 1]
#define SSR_STEPS 16                    // Screen Space Reflection Steps                [4 6 8 12 16 32]
#define SSR_DEPTH_TOLERANCE 1.0         // Modifier to the thickness estimation         [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0 3.25 3.5 3.75 4.0 4.25 4.5 4.75 5.0 1000]
#define SSR_FINE_STEPS 3

//#define SSR_NO_REFINEMENT

#define REFRACTION
#define REFRACTION_AMOUNT 0.03          // Refraction Strength                          [0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1]


#define SCREEN_SPACE_AMBIENT_OCCLUSION
#define SSAO_QUALITY 1                  // SSAO Quality                                 [1 2]
#define SSAO_STRENGTH 0.80              // SSAO Strength                                [0.00  0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

// Depth of Field
/////////////////////////////////////////////////////////////////////////////////////////

#define DOF_MODE 0                   // Lens Blur Mode                                          [0 3 4]
#define DOF_STEPS 3                  // Depth of Field Step Size                                [1 2 3 4 5 6 7 8 9 10]
#define DOF_STRENGTH 1.0             // Depth of Field Intensity                                [0.25 0.5 1.0 1.5 2.0 2.5 3 3.5]

//#define DOF_DITHER                 // Randomize Samples in order to conceil high step sizes   
#define DOF_DITHER_AMOUNT 0.5        // Amount of randomization                                 [0.2 0.3 0.4 0.5 0.6 0.7 0.8]

#define DOF_DOWNSAMPLING 0.5         // How much downsampling takes place for the DoF effect    [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define DOF_KERNEL_SIZE 2            // Bokeh Quality                                           [1 2 3 4]           
#define DOF_MAXSIZE 0.007            // Maximum Blur                                            [0.002 0.005 0.007 0.03 1.0]

#define FOCUS_SPEED 1.0



// Post-Processing
/////////////////////////////////////////////////////////////////////////////////////////

//#define MOTION_BLUR
#define MOTION_BLUR_STRENGTH 0.25       // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define MOTION_BLUR_SAMPLES 4           // [1 4]
#define MOTION_BLUR_QUALITY 0           // [0 1]

#define CHROMATIC_ABERRATION_AMOUNT 5   // [0 1 2 3 4 5 6 7 8 9 10]
const float chromaticAberration = float(CHROMATIC_ABERRATION_AMOUNT) * 0.1;

#define BLOOM 
#define BLOOM_AMOUNT 0.35               // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

#define SATURATION 1.0                  // Saturation               [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

#define GODRAYS
#define GODRAY_STEPS 5                  // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
#define GODRAY_STRENGTH 0.35            // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

// Misc
/////////////////////////////////////////////////////////////////////////////////////////

//#define TAA
#define TAA_BLEND 0.20                  // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75]
#define TAA_JITTER_AMOUNT 1.0

#define OUTLINE
#define OUTLINE_DISTANCE 1.0            // How far does the outline reach    [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5]
#define OUTLINE_BRIGHTNESS 0.6          // How bright is the outline         [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define FOG 1                           // [0 1 2]
#define FOG_AMOUNT 1.0                  // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0]

#define EMISSION_STRENGTH 5

#define EXPOSURE 1.00                   // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00 1.00 1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.10 1.11 1.12 1.13 1.14 1.15 1.16 1.17 1.18 1.19 1.20 1.21 1.22 1.23 1.24 1.25 1.26 1.27 1.28 1.29 1.30 1.31 1.32 1.33 1.34 1.35 1.36 1.37 1.38 1.39 1.40 1.41 1.42 1.43 1.44 1.45 1.46 1.47 1.48 1.49 1.50 1.51 1.52 1.53 1.54 1.55 1.56 1.57 1.58 1.59 1.60 1.61 1.62 1.63 1.64 1.65 1.66 1.67 1.68 1.69 1.70 1.71 1.72 1.73 1.74 1.75 1.76 1.77 1.78 1.79 1.80 1.81 1.82 1.83 1.84 1.85 1.86 1.87 1.88 1.89 1.90 1.91 1.92 1.93 1.94 1.95 1.96 1.97 1.98 1.99 2.00]

#define HAND_INVISIBILITY_EFFECT

//#define SHARPEN
#define SHARPEN_AMOUNT 1.0              // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0]


// PBR
/////////////////////////////////////////////////////////////////////////////////////////

//#define PHYSICALLY_BASED
#define FRAG_NORMALS       // Calculates the TBN matrix in the fragment instead of in the vertex shader (more performance intensive, but fixes at_tangent not working for some elements of the game)

#define PBR_BLEND 0.75 // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]

//#define HEIGHT_AO

#define HARDCODED_METALS

// Gbuffers
/////////////////////////////////////////////////////////////////////////////////////////

//#define FAST_SKY

#define WATER_WAVES
#define WATER_WAVE_AMOUNT 1.0			// Physical Wave Height 			[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define WATER_NORMALS_AMOUNT 1.0		// "Fake" Wave strength     		[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define WATER_NORMALS_SIZE 1.5          // Size of the Waves                [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0]

#define WAVY_BLOCKS
#define WAVY_LEAVES

//#define WORLD_CURVE
#define WORLD_CURVE_RADIUS 512 //[64 128 256 512 1024 2048 4096]

#define CREDITS 0
#ifdef CREDITS
#endif