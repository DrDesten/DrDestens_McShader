#version 150 compatibility
#extension GL_ARB_explicit_attrib_location : enable
#define NETHER
#define VERT
void main() {
    gl_Position = ftransform();
}