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

uniform float near;
uniform float far;

vec3 chromaticAberrationTint(vec2 relPos) {
    float chromAbb     = relPos.x * chromaticAberration + 0.5;
    vec3  chromAbbTint = vec3(chromAbb, 0.75 - abs(chromAbb - 0.5), 1 - chromAbb) * 2;
    return chromAbbTint;
}

//Depth of Field

vec3 bokehBlur(vec2 coord, float size) {
    vec3 pixelColor = vec3(0);
    float lod = log2(size / screenSizeInverse.x) * DOF_DOWNSAMPLING; // Level of detail for Mipmapped Texture (higher -> less pixels)
    float depth = getDepth(coord);
    vec3  color = getAlbedo(coord);

    // Low Quality
    #if DOF_KERNEL_SIZE == 1
        const int kernelSize  = 4;
        const vec2[] kernel   = circle_blur_4;
        const vec2 kernel_com = circle_blur_4_com;

    // Medium Quality
    #elif DOF_KERNEL_SIZE == 2
        const int kernelSize  = 16;
        const vec2[] kernel   = circle_blur_16;
        const vec2 kernel_com = circle_blur_16_com;
    
    // High Quality
    #elif DOF_KERNEL_SIZE == 3
        const int kernelSize  = 32;
        const vec2[] kernel   = circle_blur_32;
        const vec2 kernel_com = circle_blur_32_com;

    // Very High Quality
    #elif DOF_KERNEL_SIZE == 4
        const int kernelSize  = 64;
        const vec2[] kernel   = circle_blur_64;
        const vec2 kernel_com = circle_blur_64_com;

    #endif

    #ifdef DOF_DITHER
        // Use Bayer Dithering to vary the DoF, helps with small kernels
        vec2 dither = (vec2(Bayer4(coord * screenSize), Bayer4(coord * screenSize + 1)) - 0.5) * (size * inversesqrt(kernelSize * .25));
    #else
        const vec2 dither = vec2(0);
    #endif

    #if CHROMATIC_ABERRATION_AMOUNT != 0

        vec3 totalTint = vec3(0);
        for (int i = 0; i < kernelSize; i++) {
            vec3  chromAbbTint = chromaticAberrationTint(kernel[i]);
            vec3  sampleColor  = textureLod(colortex0, coord + (kernel[i] * size + dither), lod).rgb * chromAbbTint;
            pixelColor        += sampleColor;
            totalTint         += chromAbbTint;
        }
        pixelColor /= totalTint;

    #else

        for (int i = 0; i < kernelSize; i++) {
            #ifdef DOF_DEPTH_REJECTION
            float sampleDepth = getDepth_int(coord + (kernel[i] * size + dither));
            float weight      = float( depth - 0.01 > sampleDepth || sampleDepth < 0.56);
            pixelColor        += mix(textureLod(colortex0, coord + (kernel[i] * size + dither), lod).rgb, pixelColor/(i+1) , weight);
            #else
            pixelColor += textureLod(colortex0, coord + (kernel[i] * size + dither), lod).rgb;
            #endif
        }
        pixelColor /= kernelSize;

    #endif

    return pixelColor;
}

vec3 bokehBlur_adaptive(vec2 coord, float size) {
    vec3 pixelColor = vec3(0);
    float radius    = size * screenSize.x;

    // Low Quality
    #if DOF_KERNEL_SIZE == 1
        const float samplesPerRadius = 0.25;
        const int   minSamples = 4;
        const int   maxSamples = 8;

    // Medium Quality
    #elif DOF_KERNEL_SIZE == 2
        const float samplesPerRadius = 2.0;
        const int   minSamples = 6;
        const int   maxSamples = 16;

    // High Quality
    #elif DOF_KERNEL_SIZE >= 3
        const float samplesPerRadius = 4.0;
        const int   minSamples = 6;
        const int   maxSamples = 32;

    #endif

    float lod     = log2(radius * 4 / minSamples) * DOF_DOWNSAMPLING; // Level of detail for Mipmapped Texture (higher -> less pixels)
    int   samples = clamp(int(radius * samplesPerRadius), minSamples, maxSamples); // Circle blur Array has a max of 64 samples

    #if CHROMATIC_ABERRATION_AMOUNT != 0
        vec3 totalTint = vec3(0); // Contains the combined tint of all sample pixels, used for color correction
    #endif

    #ifdef DOF_DITHER
        float offset      = Bayer2(coord * screenSize) * 32;
        for (int i = 0; i < samples; i++) {
            int index     = int(mod(i + offset, 64));
            #if CHROMATIC_ABERRATION_AMOUNT != 0
                vec3 chromAbbTint = chromaticAberrationTint(blue_noise_disk[index]);
                pixelColor   += textureLod(colortex0, coord + (blue_noise_disk[index] * size), lod).rgb * chromAbbTint;
                totalTint    += chromAbbTint;
            #else
                pixelColor   += textureLod(colortex0, coord + (blue_noise_disk[index] * size), lod).rgb;
            #endif
        }
    #else
        for (int i = 0; i < samples; i++) {
            #if CHROMATIC_ABERRATION_AMOUNT != 0
                vec3 chromAbbTint = chromaticAberrationTint(blue_noise_disk[i]);
                pixelColor   += textureLod(colortex0, coord + (blue_noise_disk[i] * size), lod).rgb * chromAbbTint;
                totalTint    += chromAbbTint;
            #else
                pixelColor   += textureLod(colortex0, coord + (blue_noise_disk[i] * size), lod).rgb;
            #endif
        }
    #endif
    
    #if CHROMATIC_ABERRATION_AMOUNT != 0
        // "Normal" Calculation:
        //totalTint  /= samples; pixelColor /= totalTint; pixelColor /= samples;
        // Faster version:
        pixelColor  /= totalTint;
    #else
        pixelColor  /= samples;
    #endif

    return pixelColor;
}

vec3 DoF(vec2 coord, float pixeldepth, float size) {
    if (pixeldepth < 0.56 || size < 0.5 / screenSize.x) {return getAlbedo(coord);}
    size = min(size, DOF_MAXSIZE);

    // precompiler instead of runtime check
    #if DOF_MODE == 3
        return bokehBlur(coord, size);
    #elif DOF_MODE == 4
        return bokehBlur_adaptive(coord, size);
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

/////////////////////////////////////////////////////////////////////////////////////
//                              BLOOM
/////////////////////////////////////////////////////////////////////////////////////

vec3 getBloomTiles(vec2 coord, float scale, int tiles, float padding) {

    vec2 bloomCoord = coord * scale;
    
    for (int i = 1; i < tiles; i++) {

        float padd = padding * exp2(i-1) * scale;

        // Check if the x-coordinate exceeds 1 (out of bounds)
        if (bloomCoord.x > 1 + padd) {
            // Bring back by 1 (back into bounds)
            bloomCoord.x -= 1 + padd;
            // Half the size of the tile
            bloomCoord   *= 2;
        } else {
            break;
        }

    }
    if (bloomCoord != saturate(bloomCoord)) {
        return vec3(0);
    }

    return texture(colortex0, bloomCoord).rgb;
}
/* vec3 getBloomTilesBlur(vec2 coord, float scale, int tiles, float padding) {

    // Get Tile Coordinates
    vec2 bloomCoord = coord * scale;
    
    int currentTile = -1;
    for (int i = 1; i < tiles; i++) {

        float padd = padding * exp2(i-1) * scale;

        // Check if the x-coordinate exceeds 1 (out of bounds)
        if (bloomCoord.x > 1 + padd) {
            // Bring back by 1 (back into bounds)
            bloomCoord.x -= 1 + padd;
            // Half the size of the tile
            bloomCoord   *= 2;
        } else {
            currentTile   = i;
            break;
        }

    }
    
    if (bloomCoord != saturate(bloomCoord)) {
        return vec3(0);
    }  

    // Gaussian Blur
    vec2 pixelStep = screenSizeInverse * exp2(currentTile - 1) * scale * 1.5;

    vec3 color = vec3(0);
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {

            float weight = gaussian_5[x + 2] * gaussian_5[y + 2];
            vec2  offs   = vec2(x, y) * pixelStep;

            color       += texture(colortex0, bloomCoord + offs).rgb * weight;
        }
    }

    // Reduces Bloom artifacts on IntelHD (seems to be a hardware mipmapping issue)
    return (bloomCoord == clamp(bloomCoord, pixelStep, 1 - pixelStep)) ? color : vec3(0);
    //return color;
} */
vec3 getBloomTilesBlur(vec2 coord, float tiles, float padding) {

    float currentTile = ceil( -log2(1 - coord.x) ); // Gets the current tile
    // Log2(x) returns the exponent necessary to get to the coordinate.
    // we use 1-x because we want to start from the left
    // invert because the exponents are negative
    // ceil() to get the tile number

    float xOffset    = 1 - exp2( 1 - currentTile ); // Tbh I'm not even sure how this works (but it does)
    float tileScale  = exp2( currentTile );         // 2^tile gives us the scaling factor for each tile
    vec2  tileCoords = vec2(coord.x - xOffset, coord.y) * tileScale * (tileScale * padding + 1);

    if (tileCoords != saturate(tileCoords)) {
        return vec3(0);
    }

    vec2 stepSize = screenSizeInverse * tileScale * 1.5;
    vec3 color    = vec3(0);
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            
            float weight = gaussian_5[x + 2] * gaussian_5[y + 2];
            vec2  offs   = vec2(x, y) * stepSize;

            color       += textureLod(colortex0, tileCoords + offs, floor(currentTile + 0.5)).rgb * weight;

        }
    }

    return color;
}

#ifdef BLOOM
/* DRAWBUFFERS:04 */
#else
/* DRAWBUFFERS:0 */
#endif

void main() {
    float depth         = texture(depthtex1, coord).r;

    // Disables Depth of Field in the precompiler
    #if DOF_MODE != 0
 
        float linearDepth   = linearizeDepth(depth, near, far);
        float clinearDepth  = linearizeDepth(centerDepthSmooth, near, far);

        float Blur = realCoC(linearDepth, clinearDepth) * fovScale * DOF_STRENGTH;

        vec3 color = DoF(coord, depth, Blur);

    #else
        vec3 color          = getAlbedo(coord);
    #endif

    #ifdef BLOOM
        vec3 bloomColor = getBloomTilesBlur(coord, 6, 10 / screenSize.x) * BLOOM_AMOUNT;
    #endif

    //Pass everything forward
    FD0          = vec4(color,  1);
    #ifdef BLOOM
    FD1          = vec4(bloomColor, 1);
    #endif
}
