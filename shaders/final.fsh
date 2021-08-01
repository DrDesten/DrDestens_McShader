#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

in vec2 coord;

void main() {
    vec3 color = getAlbedo(coord);

    #ifdef SHARPEN
        vec3 edge  = dFdx(color) + dFdy(color);
        color     += sq(edge) * SHARPEN_AMOUNT;
    #endif


    // Remove Banding (yay)
    float displayPrecision = 1./255.;
    color                 += vec3((Bayer4(coord * ScreenSize) - .5) * displayPrecision);

    gl_FragColor = vec4(color, 1.0);
}

