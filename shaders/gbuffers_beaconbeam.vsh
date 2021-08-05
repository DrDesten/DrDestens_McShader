#version 120

varying vec3 normal;

varying vec2 coord;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();
	
	normal = normalize(gl_NormalMatrix * gl_Normal);

	coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}