#include "/lib/settings.glsl"
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

varying vec2 lmcoord;
varying vec4 glcolor;

void main() {
	vec4 clipPos = ftransform();
	
	#ifdef WORLD_CURVE
		#if MC_VERSION < 11700
			#include "/lib/world_curve.glsl"
		#else
			if (renderStage != MC_RENDER_STAGE_OUTLINE) {
				#include "/lib/world_curve.glsl"
			}
		#endif
	#endif
	
	#ifdef TAA
		clipPos.xy += TAAOffsets[int( mod(frameCounter, 4) )] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif

	gl_Position    = clipPos;
	gl_Position.z -= 5e-4;

	lmcoord = getLmCoord();
	glcolor = gl_Color;
}