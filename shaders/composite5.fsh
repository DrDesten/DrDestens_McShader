#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         DEPTH OF FIELD
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

#define DOF_MODE 3                   // Lens Blur Mode                                          [0 3 4]
#define DOF_STEPS 3                  // Depth of Field Step Size                                [1 2 3 4 5 6 7 8 9 10]
#define DOF_STRENGTH 1.0             // Depth of Field Intensity                                [0.25 0.5 1.0 1.5 2.0 2.5 3 3.5]

//#define DOF_RANDOMIZE              // Randomize Samples in order to conceil high step sizes   
#define DOF_RANDOMIZE_AMOUNT 0.5     // Amount of randomization                                 [0.2 0.3 0.4 0.5 0.6 0.7 0.8]

#define DOF_DOWNSAMPLING 0.5         // How much downsampling takes place for the DoF effect    [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define DOF_KERNEL_SIZE 2            // Bokeh Quality                                           [1 2 3 4]           
#define DOF_MAXSIZE 0.005            // Maximum Blur                                            [0.002 0.005 0.007 0.02 1.0]

#define FOCUS_SPEED 1.0

#define FOG
#define FOG_AMOUNT 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0]


uniform float centerDepthSmooth;
const float   centerDepthHalflife = 1.0;

const bool    colortex0MipmapEnabled = true; //Enabling Mipmapping

in vec2       coord;
flat in vec2  pixelSize;

uniform int   frameCounter;
uniform float near;
uniform float far;
uniform vec3  fogColor;
uniform vec3  sunPosition;

//Depth of Field

vec3 boxBlur(vec2 coord, float size, float stepsize) {
    if (size <= pixelSize.x * 0.5)               { return getAlbedo(coord); } //Return unblurred if <1 pixel
    stepsize *= pixelSize.x;
    if (stepsize > size)                   { stepsize = size; } //Prevent blur from clipping due to lange step size

    vec3 pixelColor = vec3(0);

    float samplecount = 0.0;

    // Enable or Disable Coordinate Randomization, making use of precompiler
    #ifdef DOF_RANDOMIZE
        float randfac1 = rand11(coord);
        float randfac2 = rand11(coord + 1);
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
        float randfac1 = rand(coord) * 2 -1;
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
    vec3 pixelColor = vec3(0);
    float lod = log2(size / pixelSize.x) * DOF_DOWNSAMPLING; // Level of detail for Mipmapped Texture (higher -> less pixels)


    // Low Quality
    #if DOF_KERNEL_SIZE == 1
        const int kernelSize = 4;
        const vec2[] kernel = circle_blur_4;

    // Medium Quality
    #elif DOF_KERNEL_SIZE == 2
        const int kernelSize = 16;
        const vec2[] kernel = circle_blur_16;
    
    // High Quality
    #elif DOF_KERNEL_SIZE == 3
        const int kernelSize = 32;
        const vec2[] kernel = circle_blur_32;

    // Very High Quality
    #elif DOF_KERNEL_SIZE == 4
        const int kernelSize = 64;
        const vec2[] kernel = circle_blur_64;

    #endif

    #ifdef DOF_RANDOMIZE
        // Use Bayer Dithering to vary the DoF, helps with small kernels
        vec2 dither = (vec2(Bayer4(coord * ScreenSize), Bayer4(coord * ScreenSize + 1)) - 0.5) * (size / sqrt(kernelSize));
    #else
        vec2 dither = vec2(0);
    #endif

    for (int i = 0; i < kernelSize; i++) {
        pixelColor += textureLod(colortex0, coord + (kernel[i] * size + dither), lod).rgb;
    }


    pixelColor /= kernelSize;
    return pixelColor;
}

vec3 bokehBlur_adaptive(vec2 coord, float size, float stepsize) {
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
    if (pixeldepth < 0.56 || size < 0.5 / ScreenSize.x) {return getAlbedo(coord);}
    size = min(size, DOF_MAXSIZE);

    // precompiler instead of runtime check
    #if DOF_MODE == 2
        return boxBlur_exp(coord, size * 0.70710, stepsize);
    #elif DOF_MODE == 3
        return bokehBlur(coord, size * 1, stepsize);
    #elif DOF_MODE == 4
        return bokehBlur_adaptive(coord, size * 1, stepsize);
    #endif

    return vec3(0);
}

float CoC(float depth) {
    depth = (depth * 4) - 3;
    depth *= depth;
    return depth;
}


/* DRAWBUFFERS:0 */

void main() {
    float depth         = getDepth(coord);

    // Disables Depth of Field in the precompiler
    #if DOF_MODE != 0

        float fovScale      = gbufferProjection[1][1] * 0.7299270073;

        float mappedDepth   = CoC(depth);
        float lookDepth     = CoC(centerDepthSmooth); //Depth of center pixel (mapped)
        float blurDepth     = abs(mappedDepth - lookDepth) * DOF_STRENGTH * 0.02 * fovScale; 

        color = DoF(coord, depth, blurDepth, DOF_STEPS); // DOF_MODE, DOF_STEPS -> Settings Menu

    #else
        vec3 color          = getAlbedo(coord);
    #endif


    #ifdef FOG

        // Fog
        // Increase Fog when looking at sun/moon
        vec4  sunProjection  = gbufferProjection * vec4(sunPosition, 1.0);
        vec3  sunScreenSpace = (sunProjection.xyz / sunProjection.w) * 0.5 + 0.5;
        float sunDist        = clamp(distance(coord, sunScreenSpace.xy), 0, 1);
        float sunFog         = smoothstep(0.5, 1, 1-sunDist) * 2;

        // Blend between FogColor and normal color based on sqare distance
        vec3  playerpos = toPlayerEye(toView(vec3(coord, depth) * 2 - 1));
        float dist      = dot(playerpos, playerpos) * float(depth != 1);
        float fog       = clamp(dist * 3e-6 * FOG_AMOUNT * (sunFog + 1), 0, 1);

        color           = mix(color, (color * 0.1) + fogColor, fog);

    #endif

    //Pass everything forward
    FD0          = vec4(color,  1);
}
