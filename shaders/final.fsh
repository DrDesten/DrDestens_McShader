#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

in vec2 coord;

void main() {
    vec3 color = getAlbedo(coord);

    // Remove Banding (yay)
    float displayPrecision = 1./255.;
    color                 += vec3((Bayer4(coord * screenSize) - .5) * displayPrecision);

    gl_FragColor = vec4(color, 1.0);
}

