#version 120

varying vec2 texcoord;
varying vec3 normal;
varying vec3 viewPos;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();
	
	normal = normalize(gl_NormalMatrix * gl_Normal);
	viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}