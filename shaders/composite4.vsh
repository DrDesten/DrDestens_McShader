#version 130

uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;

varying vec2 x3_kernel[9];

void main() {
    gl_Position = ftransform();

    texcoord = gl_MultiTexCoord0.st;

    float pixelWidth = 1.0 / viewWidth;
    float pixelHeight = 1.0 / viewHeight;

    for (int i = 0; i < 3; i++) {
        for (int o = 0; o < 3; o++) {
            vec2 stepsize = vec2(pixelWidth * (i-1), pixelHeight * (o-1));

            x3_kernel[o * 3 + i] = texcoord + stepsize;
        }
    }

}