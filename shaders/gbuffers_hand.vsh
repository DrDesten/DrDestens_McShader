

#include "/lib/settings.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

attribute vec4 mc_Entity;
attribute vec4 at_tangent;

#ifdef TAA
uniform int  frameCounter;
uniform vec2 screenSizeInverse;
#endif

#ifdef PHYSICALLY_BASED
varying vec3 viewpos;
#endif
varying vec2  lmcoord;
varying vec2  coord;

varying vec4 glcolor;

// Switch on or off Fragment based normal mapping
#ifdef FRAG_NORMALS
varying vec3 N;
#else
varying mat3 tbn;
#endif

void main() {
	vec4 clipPos = ftransform();
	
	#ifdef TAA
		clipPos.xy += TAAOffsets[int( mod(frameCounter, 6) )] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif

	gl_Position  = clipPos;

	#ifdef PHYSICALLY_BASED
	viewpos = getView();
	#endif
	lmcoord = getLmCoord();
	coord   = getCoord();
	#ifdef FRAG_NORMALS
	N  		= getNormal();
	#else
	tbn     = getTBN(at_tangent);
	#endif

	glcolor = gl_Color;
}