#version 120

attribute vec4 at_tangent;
attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;


varying float blockId;
varying vec3 viewpos;
varying vec2 lmcoord;
varying vec2 coord;
varying vec2 mid_coord;
varying vec4 glcolor;

flat varying mat3 tbn;

void main() {
	gl_Position = ftransform();
	vec3 normal = normalize(gl_NormalMatrix * gl_Normal);
	viewpos = (gl_ModelViewMatrix * gl_Vertex).xyz;

	coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	mid_coord = mc_midTexCoord;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	vec3 tangent = gl_NormalMatrix * (at_tangent.xyz / at_tangent.w);
	tbn = mat3(tangent, cross(tangent, normal), normal);
	
	blockId = mc_Entity.x;
	glcolor = gl_Color;
}