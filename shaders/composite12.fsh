#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"
#include "/lib/bloom.glsl"

#define FXAA
#define FXAA_THRESHOLD 0.5            //When does FXAA kick in            [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
//#define FXAA_DEBUG

uniform int worldTime;
uniform float frameTimeCounter;

const bool colortex0MipmapEnabled = true;

in vec2 coord;

vec2 pixelSize = vec2(1 / viewWidth, 1 / viewHeight);


// Color Grade

void colorGrade(inout vec3 color, vec3 colorMults) {
    color *= colorMults;
}
void colorGradeMidtones(inout vec3 color, vec3 colorMults) {
    float colMean = mean(color);
    vec3 newColorMults = colorMults - vec3(1); // Calculate difference to non-modified values
    newColorMults *= max(-pow(colMean + 0.1, 4) + 1, 0); // multiply changes by Falloff curve (-x^4 +1)
    newColorMults += vec3(1); // readd 1 to make normal
    color *= newColorMults;
}

vec3 convHDR(in vec3 color, float over, float under) { //Changes Vibrance and Contrast
    vec3 HDRImage;
    vec3 overexposed = color * over;
    vec3 underexposed = color / under;

    HDRImage = mix(underexposed, overexposed, color);

    return HDRImage;
}

vec3 cheapFXAA(vec2 coord, float threshold) {
    vec3 color          = getAlbedo(coord);
    vec3 color_average  = getAlbedo_int(coord + (pixelSize * 0.5));

    float diff = sum(abs(color - color_average));

    // Branchless if (diff > 0.5) { return color_average; }
    color -= color * int(diff > threshold);                      // make (0,0,0) if true
    
    #ifdef FXAA_DEBUG
        color += vec3(1, 1, 0) * int(diff > threshold); //(color + color_average) * (int(diff > threshold));    // set to color_average
    #else
        color += color_average * int(diff > threshold);    // set to color_average
    #endif

    return color;
}

vec3 AntiSpeckleX4(vec2 coord, float threshold, float amount) {
    vec2 pixelOffset = pixelSize * amount;

    vec3 color           = getAlbedo(coord);
    vec2 coordOffsetPos  = coord + pixelOffset;
    vec2 coordOffsetNeg  = coord - pixelOffset;

    vec3 color_surround[4]  = vec3[4](
        getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetPos.y)),
        getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetPos.y)),
        getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetNeg.y)),
        getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetNeg.y))
    );

    for (int i = 0; i < 4; i++) {
        if ((sum(color) - sum(color_surround[i])) > threshold) {color = color_surround[i];}
    }

    return color;
}

vec3 AntiSpeckleX8(vec2 coord, float amount) {
    vec2 pixelOffset = pixelSize * amount;

    vec3 color           = getAlbedo(coord);
    vec2 coordOffsetPos  = coord + pixelOffset;
    vec2 coordOffsetNeg  = coord - pixelOffset;

    vec3 color_surround[8]  = vec3[8](
        getAlbedo_int(vec2(coordOffsetPos.x,  coord.y         )),
        getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetPos.y)),
        getAlbedo_int(vec2(coord.x,           coordOffsetPos.y)),
        getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetPos.y)),
        getAlbedo_int(vec2(coordOffsetNeg.x,  coord.y         )),
        getAlbedo_int(vec2(coordOffsetNeg.x,  coordOffsetNeg.y)),
        getAlbedo_int(vec2(coord.x,           coordOffsetNeg.y)),
        getAlbedo_int(vec2(coordOffsetPos.x,  coordOffsetNeg.y))
    );

    for (int i = 0; i < 8; i++) {
        if (sum(color) > sum(color_surround[i])) {color = color_surround[i];}
    }

    return color;
}


/* DRAWBUFFERS:0 */

void main() {
    float daynight;
    vec3 color;

    #ifdef FXAA
        color = cheapFXAA(coord, FXAA_THRESHOLD);
    #else
        color = getAlbedo(coord);
    #endif

    #ifdef BLOOM
        vec2 bloomCoord = clamp(coord * 0.05 - (pixelSize * 0.5), 0, 0.05 - 1.5/viewHeight);
        vec3 bloomColor = (texture(colortex5, bloomCoord).rgb);

        color += (bloomColor * bloomColor) * BLOOM_AMOUNT * 20;
    #endif

    //Pass everything forward
    FD0 = vec4(color, 1);
}