#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

uniform int frameCounter;

in vec2 coord;

vec3 normalAwareBlur(vec2 coord, float size, float stepsize) {
    vec3 normal = getNormal(coord);
    vec3 color = vec3(0);

    float samples = 0;

    for( float x = -size; x <= size; x++ ) {
        for( float y = -size; y <= size; y++ ) {

            vec2 samplePos    = vec2(x, y) * stepsize * screenSizeInverse + coord;
            vec3 sampleNormal = getNormal(samplePos);

            float blend       = clamp(dot(normal, sampleNormal) * 2 - 1, 0, 1);

            color            += getAlbedo_int(samplePos) * blend;
            samples          += blend;
        
        }
    }


    return color / samples;
}

void main() {
    vec3 color = getAlbedo(coord);
    
    /* #ifdef TAA
        color = getAlbedo_int(coord + blue_noise_disk[int( mod(frameCounter, 64) )] * TAA_JITTER_AMOUNT * screenSizeInverse);
    #endif */

    // Remove Banding (yay)
    float displayPrecision = 1./255.;
    color                 += vec3((Bayer4(coord * screenSize) - .5) * displayPrecision);

    gl_FragColor = vec4(color, 1.0);
}

