#version 130

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         DEPTH OF FIELD
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

uniform sampler2D depthtex1;

uniform float centerDepthSmooth;
const float   centerDepthHalflife = 1.5;

const bool    colortex0MipmapEnabled = true; //Enabling Mipmapping

in vec2       coord;
flat in vec2  pixelSize;

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
    #ifdef DOF_DITHER
        float randfac1 = rand11(coord);
        float randfac2 = rand11(coord + 1);
    #endif        
    
    for (float i = -size; i < size; i += stepsize) {
        for (float o = -size; o < size; o += stepsize) {
            vec2 sampleCoord = vec2(coord.x + i, coord.y + o);

            // Enable or Disable Coordinate Randomization, making use of precompiler
            #ifdef DOF_DITHER
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
    #ifdef DOF_DITHER
        float randfac1 = rand(coord) * 2 -1;
        float randfac2 = randfac1;
    #endif
    
    for (float i = -size; i < size; i += stepsize) {
        for (float o = -size; o < size; o += stepsize) {
            vec2 sampleCoord = vec2(coord.x + i, coord.y + o);

            // Enable or Disable Coordinate Randomization, making use of precompiler
            #ifdef DOF_DITHER
            sampleCoord += vec2(randfac1, randfac2) * (stepsize - pixelSize.x) * DOF_DITHER_AMOUNT;
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

    #ifdef DOF_DITHER
        // Use Bayer Dithering to vary the DoF, helps with small kernels
        vec2 dither = (vec2(Bayer4(coord * ScreenSize), Bayer4(coord * ScreenSize + 1)) - 0.5) * (size * inversesqrt(kernelSize * .25));
    #else
        vec2 dither = vec2(0);
    #endif

    for (int i = 0; i < kernelSize; i++) {
        pixelColor += textureLod(colortex0, coord + (kernel[i] * size + dither), lod).rgb;
    }


    pixelColor /= kernelSize;
    return pixelColor;
}

/* vec3 bokehBlur_adaptive_old(vec2 coord, float size, float stepsize) {
    vec3 pixelColor = vec3(0);
    float radius = size / pixelSize.x;

    float lod = log2(radius) * DOF_DOWNSAMPLING; // Level of detail for Mipmapped Texture (higher -> less pixels)

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

        int mediumKernelSize = 8;
        vec2[] mediumKernel = circle_blur_8;

        int highKernelSize = 32;
        vec2[] highKernel = circle_blur_32;

    // High Quality
    #elif DOF_KERNEL_SIZE >= 3
        int lowKernelSize = 8;
        vec2[] lowKernel = circle_blur_8;

        int mediumKernelSize = 32;
        vec2[] mediumKernel = circle_blur_32;

        int highKernelSize = 64;
        vec2[] highKernel = circle_blur_64;

    #endif

    #ifdef DOF_DITHER
        // Use Bayer Dithering to vary the DoF, helps with small kernels
        vec2 dither = (vec2(Bayer4(coord * ScreenSize), Bayer4(coord * ScreenSize + 1)) - 0.5) * (size * inversesqrt(mediumKernelSize * .25));
    #else
        vec2 dither = vec2(0);
    #endif

    if (radius < 5) { // Under 5 pixel blur 

        for (int i = 0; i < lowKernelSize; i++) {
            pixelColor += textureLod(colortex0, coord + (lowKernel[i] * size + dither), lod).rgb;
        }
        pixelColor /= lowKernelSize;

    } else if (radius < 8) { // under 8 pixel blur

        for (int i = 0; i < mediumKernelSize; i++) {
            pixelColor += textureLod(colortex0, coord + (mediumKernel[i] * size + dither), lod).rgb;
        }
        pixelColor /= mediumKernelSize;

    } else { // over 8 pixel blur

        for (int i = 0; i < highKernelSize; i++) {
            pixelColor += textureLod(colortex0, coord + (highKernel[i] * size + dither), lod).rgb;
        }

        pixelColor /= highKernelSize;
    } 

    return pixelColor;
} */
vec3 bokehBlur_adaptive(vec2 coord, float size, float stepsize) {
    vec3 pixelColor = vec3(0);
    float radius    = size * ScreenSize.x;

    // Low Quality
    #if DOF_KERNEL_SIZE == 1
        const float samplesPerRadius = 0.25;
        const int   minSamples = 4;

    // Medium Quality
    #elif DOF_KERNEL_SIZE == 2
        const float samplesPerRadius = 2.0;
        const int   minSamples = 6;

    // High Quality
    #elif DOF_KERNEL_SIZE >= 3
        const float samplesPerRadius = 4.0;
        const int   minSamples = 8;

    #endif

    float lod   = log2(radius * 8 / minSamples) * DOF_DOWNSAMPLING; // Level of detail for Mipmapped Texture (higher -> less pixels)
    int samples = clamp(int(radius * samplesPerRadius), minSamples, 64); // Circle blur Array has a max of 64 samples

    #ifdef DOF_DITHER
        float offset      = Bayer2(coord * ScreenSize) * 32;
        for (int i = 0; i < samples; i++) {
            int index     = int(mod(i + offset, 63));
            pixelColor   += textureLod(colortex0, coord + (blue_noise_disk[index] * size), lod).rgb;
        }
    #else
        for (int i = 0; i < samples; i++) {
            pixelColor += textureLod(colortex0, coord + (blue_noise_disk[i] * size), lod).rgb;
        }
    #endif
    
    pixelColor /= samples;

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

#define PLANE_DIST 5e-3
float realCoC(float linearDepth, float centerLinearDepth) {
    float focallength = 1 / ((1/centerLinearDepth) + (1/PLANE_DIST));

    float zaehler = focallength * (centerLinearDepth - linearDepth);
    float nenner  = linearDepth * (centerLinearDepth - focallength);
    return abs(zaehler / nenner);
}

vec3 getBloomTiles(vec2 coord, float scale, int tiles) {
    vec2 bloomCoord = coord * scale;
    for (int i = 1; i < tiles; i++) {

        // Check if the x-coordinate exceeds 1 (out of bounds)
        if (bloomCoord.x > 1) {
            // Bring back by 1 (back into bounds)
            bloomCoord.x -= 1;
            // Half the size of the tile
            bloomCoord   *= 2;
        }

    }
    return texture(colortex0, bloomCoord).rgb;
}

/* DRAWBUFFERS:04 */

void main() {
    float depth         = texture(depthtex1, coord).r;

    // Disables Depth of Field in the precompiler
    #if DOF_MODE != 0
 
        float linearDepth   = linearizeDepth(depth, near, far);
        float clinearDepth  = linearizeDepth(centerDepthSmooth, near, far);

        float Blur = realCoC(linearDepth, clinearDepth) * fovScale * DOF_STRENGTH;

        vec3 color = DoF(coord, depth, Blur, DOF_STEPS); // DOF_MODE, DOF_STEPS -> Settings Menu

    #else
        vec3 color          = getAlbedo(coord);
    #endif

    #ifdef BLOOM
        vec3 bloomColor = getBloomTiles(coord, 4, 5);
    #else
        vec3 bloomColor = vec3(0);
    #endif

    //Pass everything forward
    FD0          = vec4(color,  1);
    FD1          = vec4(bloomColor, 1);
}
