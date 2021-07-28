#version 120

varying vec2 coord;

void main() {
    gl_Position = ftransform();

    coord = gl_MultiTexCoord0.st;
}