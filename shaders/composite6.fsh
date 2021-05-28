#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         DEPTH OF FIELD
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

#define DOF_MODE 3                   // Lens Blur Mode                                          [0 3 4]
#define DOF_STEPS 3                  // Depth of Field Step Size                                [1 2 3 4 5 6 7 8 9 10]
#define DOF_STRENGTH 1.0             // Depth of Field Intensity                                [0.25 0.5 1.0 1.5 2.0 2.5 3 3.5]

#define DOF_RANDOMIZE                // Randomize Samples in order to conceil high step sizes   
#define DOF_RANDOMIZE_AMOUNT 0.5     // Amount of randomization                                 [0.2 0.3 0.4 0.5 0.6 0.7 0.8]

#define DOF_DOWNSAMPLING 0.5         // How much downsampling takes place for the DoF effect    [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define DOF_KERNEL_SIZE 2            // Bokeh Quality                                           [1 2 3 4]           
#define DOF_MAXSIZE 0.005            // Maximum Blur                                            [0.002 0.005 0.007 0.02 1.0]

#define FOCUS_SPEED 1.0

uniform float centerDepthSmooth;
const float   centerDepthHalflife = 1.0;

const bool    colortex0MipmapEnabled = true; //Enabling Mipmapping

in vec2       coord;
flat in vec2  pixelSize;

uniform mat4  gbufferProjection;

uniform int   frameCounter;
uniform float near;
uniform float far;

//Depth of Field

vec3 boxBlur(vec2 coord, float size, float stepsize) {
    if (size <= pixelSize.x * 0.5)               { return getAlbedo(coord); } //Return unblurred if <1 pixel
    stepsize *= pixelSize.x;
    if (stepsize > size)                   { stepsize = size; } //Prevent blur from clipping due to lange step size

    vec3 pixelColor = vec3(0);

    float samplecount = 0.0;

    // Enable or Disable Coordinate Randomization, making use of precompiler
    #ifdef DOF_RANDOMIZE
        float randfac1 = rand_11(coord);
        float randfac2 = rand_11(coord + 1);
    #endif        
    
    for (float i = -size; i < size; i += stepsize) {
        for (float o = -size; o < size; o += stepsize) {
            vec2 sampleCoord = vec2(coord.x + i, coord.y + o);

            // Enable or Disable Coordinate Randomization, making use of precompiler
            #ifdef DOF_RANDOMIZE
            sampleCoord += vec2(randfac1, randfac2) * (stepsize - pixelSize.x) * 0.5;
            #endif 


            pixelColor += getAlbedo(sampleCoord);
            
            samplecount++;
        }
    }

    pixelColor /= samplecount;
    return pixelColor;
}

vec3 boxBlur_exp(vec2 coord, float size, float stepsize) {
    if (size <= pixelSize.x * 0.1 || getDepth(coord) < 0.56)               { return getAlbedo(coord); } //Return unblurred if <1 pixel
    stepsize *= pixelSize.x;
    if (stepsize > size)                         { stepsize = size; } //Prevent blur from clipping due to lange step size

    vec3 pixelColor = vec3(0);

    float samplecount = 0.0;

    // Enable or Disable Coordinate Randomization, making use of precompiler
    #ifdef DOF_RANDOMIZE
        float randfac1 = randf_01(coord) * 2 -1;
        float randfac2 = randfac1;
    #endif
    
    for (float i = -size; i < size; i += stepsize) {
        for (float o = -size; o < size; o += stepsize) {
            vec2 sampleCoord = vec2(coord.x + i, coord.y + o);

            // Enable or Disable Coordinate Randomization, making use of precompiler
            #ifdef DOF_RANDOMIZE
            sampleCoord += vec2(randfac1, randfac2) * (stepsize - pixelSize.x) * DOF_RANDOMIZE_AMOUNT;
            #endif 

            // I am using texelFetch instead of textur2D, in order to avoid linear interpolation. This increases performance
            sampleCoord.x = clamp(sampleCoord.x, 0, 1 - pixelSize.x);
            sampleCoord.y = clamp(sampleCoord.y, 0, 1 - pixelSize.y);
            ivec2 intcoords = ivec2(sampleCoord * vec2(viewWidth, viewHeight));

            pixelColor += texelFetch(colortex0, intcoords, 0).rgb;
            
            //pixelColor += getAlbedo(sampleCoord);

            samplecount++;
        }
    }

    pixelColor /= samplecount;
    return pixelColor;
}

vec3 bokehBlur(vec2 coord, float size, float stepsize) {
    if (size <= pixelSize.x * 0.5 || getDepth(coord) < 0.56)               { return getAlbedo(coord); } //Return unblurred if <0.5 pixel

    vec3 pixelColor = vec3(0);
    float lod = log2(size / pixelSize.x) * DOF_DOWNSAMPLING; // Level of detail for Mipmapped Texture (higher -> less pixels)


    // Low Quality
    #if DOF_KERNEL_SIZE == 1
        int kernelSize = 4;
        vec2[] kernel = circle_blur_4;

    // Medium Quality
    #elif DOF_KERNEL_SIZE == 2
        int kernelSize = 16;
        vec2[] kernel = circle_blur_16;
    
    // High Quality
    #elif DOF_KERNEL_SIZE == 3
        int kernelSize = 32;
        vec2[] kernel = circle_blur_32;

    // Very High Quality
    #elif DOF_KERNEL_SIZE == 4
        int kernelSize = 64;
        vec2[] kernel = circle_blur_64;
    #endif


    for (int i = 0; i < kernelSize; i++) {
        pixelColor += textureLod(colortex0, blurOffset(coord, lod) + (kernel[i] * size), lod).rgb;
    }


    pixelColor /= kernelSize;
    return pixelColor;
}

vec3 bokehBlur_adaptive(vec2 coord, float size, float stepsize) {
    if (size <= pixelSize.x * 0.5 || getDepth(coord) < 0.56)               { return getAlbedo(coord); } //Return unblurred if <0.5 pixel

    vec3 pixelColor = vec3(0);
    float pixelBlur = size / pixelSize.x;

    float lod = log2(pixelBlur) * DOF_DOWNSAMPLING; // Level of detail for Mipmapped Texture (higher -> less pixels)

    // Low Quality
    #if DOF_KERNEL_SIZE == 1
        int lowKernelSize = 4;
        vec2[] lowKernel = circle_blur_4;

        int mediumKernelSize = 4;
        vec2[] mediumKernel = circle_blur_4;

        int highKernelSize = 16;
        vec2[] highKernel = circle_blur_16;

    // Medium Quality
    #elif DOF_KERNEL_SIZE == 2
        int lowKernelSize = 4;
        vec2[] lowKernel = circle_blur_4;

        int mediumKernelSize = 16;
        vec2[] mediumKernel = circle_blur_16;

        int highKernelSize = 32;
        vec2[] highKernel = circle_blur_32;

    // High Quality
    #elif DOF_KERNEL_SIZE >= 3
        int lowKernelSize = 16;
        vec2[] lowKernel = circle_blur_16;

        int mediumKernelSize = 32;
        vec2[] mediumKernel = circle_blur_32;

        int highKernelSize = 64;
        vec2[] highKernel = circle_blur_64;

    #endif

    if (pixelBlur < 4) { // Under 4 pixel blur 

        for (int i = 0; i < lowKernelSize; i++) {
            pixelColor += textureLod(colortex0, blurOffset(coord, lod) + (lowKernel[i] * size), lod).rgb;
        }
        pixelColor /= lowKernelSize;

    } else if (pixelBlur < 8) { // under 8 pixel blur

        for (int i = 0; i < mediumKernelSize; i++) {
            pixelColor += textureLod(colortex0, blurOffset(coord, lod) + (mediumKernel[i] * size), lod).rgb;
        }
        pixelColor /= mediumKernelSize;

    } else { // over 8 pixel blur

        for (int i = 0; i < highKernelSize; i++) {
            pixelColor += textureLod(colortex0, blurOffset(coord, lod) + (highKernel[i] * size), lod).rgb;
        }

        pixelColor /= highKernelSize;
    } 

    return pixelColor;
}

vec3 DoF(vec2 coord, float pixeldepth, float size, float stepsize) {

        size = min(size, DOF_MAXSIZE);
    

    // Use precompiler instead if runtime - saves ressources
    #if DOF_MODE == 2
        return boxBlur_exp(coord, size * 0.70710, stepsize);
    #elif DOF_MODE == 3
        return bokehBlur(coord, size * 1, stepsize);
    #elif DOF_MODE == 4
        return bokehBlur_adaptive(coord, size * 1, stepsize);
    #endif

    #if DOF_MODE == 0
        return vec3(0);
    #endif
}

float CoC(float depth) {
    depth = (depth * 4) - 3;
    depth *= depth;
    return depth;
}


/* DRAWBUFFERS:0 */

void main() {
    vec3 color          = getAlbedo(coord);

    // Disables Depth of Field in the precompiler
    #if DOF_MODE != 0

        float depth         = getDepth(coord);

        float fovScale = gbufferProjection[1][1] * 0.7299270073;

        float mappedDepth   = CoC(depth);
        float lookDepth     = CoC(centerDepthSmooth); //Depth of center pixel (mapped)
        float blurDepth     = abs(mappedDepth - lookDepth) * DOF_STRENGTH * 0.02 * fovScale; 

        color = DoF(coord, depth, blurDepth, DOF_STEPS); // DOF_MODE, DOF_STEPS -> Settings Menu

    #endif

    //Pass everything forward
    
    FD0          = vec4(color,  1);
}
