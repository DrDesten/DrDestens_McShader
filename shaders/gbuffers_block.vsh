#include "/lib/settings.glsl"
#include "/lib/math.glsl"
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
 uniform int  taaIndex;
 uniform vec2 screenSizeInverse;
#endif

out float id;
out vec2  lmcoord;
out vec2  coord;
out vec4  glcolor;
out mat3  tbn;


void main() {
	gl_Position = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif
	
	#ifdef TAA
		gl_Position.xy += TAAOffsets[taaIndex] * TAA_JITTER_AMOUNT * gl_Position.w * screenSizeInverse * 2;
	#endif

	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN(at_tangent);
	id      = getID(mc_Entity);
	glcolor = gl_Color;
}