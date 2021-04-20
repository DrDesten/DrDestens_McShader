#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"


uniform sampler2D texture;

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;

void main() {
    vec4 blockColor = texture(texture, texcoord.st);

    blockColor.rgb *= tintColor;


    FD0 = blockColor;
    FD2 = vec4(normal, 1); // n*0.5+0.5 = Change range of values from -1/1 to 0/1
}