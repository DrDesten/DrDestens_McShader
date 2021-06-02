#version 120

#include "/lib/transform.glsl"

varying vec3 viewpos;
varying vec3 normal;
varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();
	normal = normalize(gl_NormalMatrix * gl_Normal);
	viewpos = (gl_ModelViewMatrix * gl_Vertex).xyz;

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	glcolor = gl_Color;
}