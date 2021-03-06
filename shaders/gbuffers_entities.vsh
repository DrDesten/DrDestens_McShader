#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

#ifdef WORLD_CURVE
 #include "/lib/vertex_transform.glsl"
#else
 #include "/lib/vertex_transform_simple.glsl"
#endif

attribute vec4 at_tangent;

#ifdef TAA
uniform int  frameCounter;
uniform vec2 screenSizeInverse;
#endif

#ifdef PHYSICALLY_BASED
out vec3 viewpos;
#endif
out vec2 lmcoord;
out vec2 coord;

out vec4 glcolor;

// Switch on or off Fragment based normal mapping
#ifdef FRAG_NORMALS
out vec3 N;
#else
out mat3 tbn;
#endif

void main() {
	gl_Position = ftransform();

	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif
	
	#ifdef TAA
		gl_Position.xy += TAAOffsets[int( mod(frameCounter, 9) )] * TAA_JITTER_AMOUNT * gl_Position.w * screenSizeInverse * 2;
	#endif
	
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