#version 120

#include "/lib/settings.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform.glsl"

attribute vec4 mc_Entity;

uniform int  frameCounter;
uniform vec2 screenSizeInverse;

flat varying float blockId;
varying vec3  viewpos;
varying vec2  lmcoord;
varying vec2  coord;

varying vec4 glcolor;

// Switch on or off Fragment based normal mapping
#ifdef FRAG_NORMALS
flat varying vec3 N;
#else
flat varying mat3 tbn;
#endif

void main() {
	vec4 clipPos = ftransform();
	
	#ifdef TAA
		clipPos.xy += TAAOffsets[int( mod(frameCounter, 6) )] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif

	gl_Position  = clipPos;

	viewpos = getView();
	lmcoord = getLmCoord();
	coord   = getCoord();
	#ifdef FRAG_NORMALS
	N  		= getNormal();
	#else
	tbn     = getTBN();
	#endif

	blockId = mc_Entity.x;
	glcolor = gl_Color;
}