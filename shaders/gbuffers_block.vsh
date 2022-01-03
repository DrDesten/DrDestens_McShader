

#include "/lib/settings.glsl"
#include "/lib/kernels.glsl"

#ifdef WORLD_CURVE
 #include "/lib/vertex_transform.glsl"
#else
 #include "/lib/vertex_transform_simple.glsl"
#endif

attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;
attribute vec4 at_tangent;

#ifdef TAA
uniform int  frameCounter;
uniform vec2 screenSizeInverse;
#endif

out float blockId;

#ifdef PHYSICALLY_BASED
out vec3 viewpos;
#endif
out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;

out mat3 tbn;

void main() {
	vec4 clipPos = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif
	
	#ifdef TAA
		clipPos.xy += TAAOffsets[int( mod(frameCounter, 9) )] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif

	gl_Position = clipPos;


	#ifdef PHYSICALLY_BASED
	viewpos = getView();
	#endif
	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN(at_tangent);

	blockId = getID(mc_Entity);
	glcolor = gl_Color;
}