#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

#ifdef TAA
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
#endif

in vec2 coord;

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
    const float displayPrecision = 1./255.;
    color                       += (Bayer4(coord * screenSize) - .5) * displayPrecision;

    gl_FragColor = vec4(color, 1.0);
}

