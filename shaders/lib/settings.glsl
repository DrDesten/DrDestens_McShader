#define WATER_EFFECTS

//#define PIXELIZE
#define PIXELIZE_SIZE 16                // Pixel Size for Pixelation Effect             [8 16 32 64 128 256 512 1024]


// Screen Space Raytracing
/////////////////////////////////////////////////////////////////////////////////////////

#define SCREEN_SPACE_REFLECTION
//#define SSR_DEBUG
#define SSR_STEPS 16                    // Screen Space Reflection Steps                [4 6 8 12 16 32]
#define SSR_DEPTH_TOLERANCE 1.0         // Modifier to the thickness estimation         [0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0 3.25 3.5 3.75 4.0 4.25 4.5 4.75 5.0 1000]
#define SSR_FINE_STEPS 5
#define SSR_STEP_OPTIMIZATION

//#define SSR_NO_REFINEMENT

#define REFRACTION
#define REFRACTION_AMOUNT 0.03          // Refraction Strength                          [0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1]

//#define DENOISE
#define DENOISE_AMOUNT 1.0              // Denoise Amount                    [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5]

#define DENOISE_THRESHOLD 0.5           // Denoise sensitivity               [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define DENOISE_QUALITY   2             // Denoise Quality                   [1 2 3]
//#define DENOISE_DEBUG

#define SCREEN_SPACE_AMBIENT_OCCLUSION
#define SSAO_QUALITY 1                  // SSAO Quality                      [1 2]
#define SSAO_STRENGTH 0.75              // SSAO Strength                     [0.00  0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

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
#define MOTION_BLUR_STRENGTH 0.50       // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]
#define MOTION_BLUR_SAMPLES 4           // [1 4]
#define MOTION_BLUR_QUALITY 0           // [0 1]

#define CHROM_ABERRATION 0              // Chromatic Aberration     [0 1 2 3 4 5 6 7 8 9 10]

#define BLOOM 
#define BLOOM_AMOUNT 0.50               // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00]

#define SATURATION 1.0                  // Saturation               [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

#define GODRAYS
#define GODRAY_STEPS 5                  // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
#define GODRAY_STRENGTH 0.50            // [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]

// Misc
/////////////////////////////////////////////////////////////////////////////////////////

#define LENS_DISTORT        0.2         // Lens Distorsion          [0.0 0.2 0.35 0.5 0.75 1.0]
#define LENS_DISTORT_SCALE  1.2         // Lens Distorsion Scaling  [1.0 1.1 1.2 1.3 1.45]

//#define FXAA
#define FXAA_THRESHOLD 0.8              //When does FXAA kick in            [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
//#define FXAA_DEBUG

#define OUTLINE
#define OUTLINE_DISTANCE 1.0            // How far does the outline reach    [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5]
#define OUTLINE_BRIGHTNESS 1.0          // How bright is the outline         [0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define FOG
#define FOG_AMOUNT 1.0                  // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0]

#define EMISSION_STRENGTH 5

// Gbuffers
/////////////////////////////////////////////////////////////////////////////////////////

//#define PHYSICALLY_BASED
#define FRAG_NORMALS       // Calculates the TBN matrix in the fragment instead of in the vertex shader (more performance intensive, but fixes at_tangent not working for some elements of the game)

#define PBR_BLEND_MIN 0.65 // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define PBR_BLEND_MAX 0.85 // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]

//#define HEIGHT_AO

//#define PBR_REFLECTION_REALISM

//#define FAST_SKY

#define WATER_WAVES
#define WATER_WAVE_AMOUNT 1.0			// Physical Wave Height 			[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define WATER_NORMALS_AMOUNT 1.0		// "Fake" Wave strength     		[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define WATER_NORMALS_SIZE 1.5          // Size of the Waves                [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0]



