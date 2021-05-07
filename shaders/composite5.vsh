#version 130

out vec2 coord;


void main() {
    gl_Position = ftransform();


    coord = gl_MultiTexCoord0.st;
}