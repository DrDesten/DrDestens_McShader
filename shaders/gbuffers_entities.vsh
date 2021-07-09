#version 120

#include "/lib/vertex_transform.glsl"

varying vec3 viewpos;
varying vec2 lmcoord;
varying vec2 coord;

varying vec4 glcolor;

flat varying mat3 tbn;

void main() {
	gl_Position = ftransform();
	
	viewpos = getView();
	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN();

	glcolor = gl_Color;
}