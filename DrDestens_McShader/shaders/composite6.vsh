#version 130

uniform float viewWidth;
uniform float viewHeight;

varying vec2 coord;



void main() {
    gl_Position = ftransform();

    coord = gl_MultiTexCoord0.st;
}