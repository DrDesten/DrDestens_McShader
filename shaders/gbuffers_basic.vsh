#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

#ifdef WORLD_CURVE
 #include "/lib/vertex_transform.glsl"
#else
 #include "/lib/vertex_transform_simple.glsl"
#endif

#ifdef TAA
 uniform int  frameCounter;
 uniform vec2 screenSizeInverse;
#endif

#if MC_VERSION >= 11700
 uniform int renderStage;
#endif

out vec2 lmcoord;
out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif
	
	#ifdef TAA
		gl_Position.xy += TAAOffsets[int( mod(frameCounter, 9) )] * TAA_JITTER_AMOUNT * gl_Position.w * screenSizeInverse * 2;
	#endif

	gl_Position.z -= 5e-4;

	lmcoord = getLmCoord();
	glcolor = gl_Color;
}