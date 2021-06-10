#version 120

varying vec2 coord;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();
	coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}