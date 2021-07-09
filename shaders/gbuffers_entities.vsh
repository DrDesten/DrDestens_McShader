#version 120

#include "/lib/vertex_transform.glsl"

varying vec3 viewpos;
varying vec2 lmcoord;
varying vec2 coord;

varying vec3 tangent;

varying vec4 glcolor;

flat varying mat3 tbn;

void main() {
	gl_Position = ftransform();
	
	viewpos = getView();
	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN();
	
    tangent = normalize(gl_NormalMatrix * (at_tangent.xyz / at_tangent.w));

	glcolor = gl_Color;
}