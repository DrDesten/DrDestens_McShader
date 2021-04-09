#version 130

varying vec3 tintColor;

void main() {
    gl_Position = ftransform();
    tintColor = gl_Color.rgb;
}