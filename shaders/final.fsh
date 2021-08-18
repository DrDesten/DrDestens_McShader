#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

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

vec3 gaussian_3x3(vec2 coord) {
    vec2 e = vec2(-.5, .5);
    vec3 color  = texture(colortex0, screenSizeInverse * e.yy + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.xx + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.yx + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.xy + coord).rgb;
    return color * 0.25;
}

vec3 sharpen(vec2 coord, float amount, float maximum) {
    vec3 blurred  = gaussian_3x3(coord);
    vec3 color    = getAlbedo(coord);

    return clamp((color - blurred) * amount, -maximum, maximum) + color;
}

void main() {
    vec3 color = getAlbedo(coord);
    
    #ifdef TAA
        float sharpen_amount = clamp(length(cameraPosition - previousCameraPosition) * 50, 1., 1.5);
        color = sharpen(coord, sharpen_amount, 0.05);
    #endif

    // Remove Banding (yay)
    float displayPrecision = 1./255.;
    color                 += vec3((Bayer4(coord * screenSize) - .5) * displayPrecision);

    gl_FragColor = vec4(color, 1.0);
}

