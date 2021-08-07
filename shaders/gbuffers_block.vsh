#version 120

#include "/lib/settings.glsl"
#include "/lib/vertex_transform.glsl"

attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;

flat varying float blockId;

varying vec3 viewpos;
varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

flat varying mat3 tbn;

void main() {
	vec4 clipPos = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif

	gl_Position = clipPos;


	viewpos = getView();
	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN();

	blockId = mc_Entity.x;
	glcolor = gl_Color;
}