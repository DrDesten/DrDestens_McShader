#version 130

varying vec3 tintColor;
varying vec3 normal;

varying vec4 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
    tintColor = gl_Color.rgb;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}