#version 120

#include "/lib/settings.glsl"
#include "/lib/vertex_transform.glsl"

varying vec3 viewpos;
varying vec2 lmcoord;
varying vec2 coord;

varying vec4 glcolor;

// Switch on or off Fragment based normal mapping
#ifdef FRAG_NORMALS
flat varying vec3 N;
#else
flat varying mat3 tbn;
#endif

void main() {
	vec4 clipPos = ftransform();

	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
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

	glcolor = gl_Color;
}