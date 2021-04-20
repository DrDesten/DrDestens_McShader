#version 130

uniform float viewWidth;
uniform float viewHeight;

out vec2 coord;
flat out vec2 pixelSize;



void main() {
    
    float pixelWidth = 1.0 / viewWidth;
    float pixelHeight = 1.0 / viewHeight;

    pixelSize = vec2(pixelWidth, pixelHeight);


    gl_Position = ftransform();
    coord = gl_MultiTexCoord0.st;
}