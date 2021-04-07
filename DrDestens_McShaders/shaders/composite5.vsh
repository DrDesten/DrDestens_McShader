#version 130

uniform float viewWidth;
uniform float viewHeight;

varying vec2 coord;
varying vec2 screenResolution;
varying vec2 pixelSize;



void main() {
    gl_Position = ftransform();

    coord = gl_MultiTexCoord0.st;

    screenResolution = vec2(viewWidth, viewHeight);

    
    float pixelWidth = 1.0 / viewWidth;
    float pixelHeight = 1.0 / viewHeight;

    pixelSize = vec2(pixelWidth, pixelHeight);

}