#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

in vec2 coord;

void main() {
    vec3 color = getAlbedo(coord);

    gl_FragColor = vec4(color, 1.0);
}

