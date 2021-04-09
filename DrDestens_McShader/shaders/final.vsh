#version 130

uniform float viewWidth;
uniform float viewHeight;

varying vec2 texcoord;


void main() {
    gl_Position = ftransform();

    texcoord = gl_MultiTexCoord0.st;

    
    float pixelWidth = 1.0 / viewWidth;
    float pixelHeight = 1.0 / viewHeight;
}