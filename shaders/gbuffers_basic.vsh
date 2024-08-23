#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/kernels.glsl"

uniform int renderStage;

#ifdef WORLD_CURVE
    #include "/core/vertex_transform.glsl"
#else
    #include "/core/vertex_transform_simple.glsl"
#endif

#ifdef TAA
    uniform vec2 taaOffset;
#endif

out vec2 lmcoord;
out vec4 glcolor;

void main() {
	#if SUPPORTS_RENDERSTAGE
	// Prevent Buggy Sky rendering
	if (
		renderStage == MC_RENDER_STAGE_SKY || 
		renderStage == MC_RENDER_STAGE_CUSTOM_SKY ||
		renderStage == MC_RENDER_STAGE_SUNSET ||
		renderStage == MC_RENDER_STAGE_STARS ||
		renderStage == MC_RENDER_STAGE_VOID
	) {
		gl_Position = vec4(-1);
		return;
	}
	#endif

	gl_Position = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif
	
	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif

	gl_Position.z -= 1e-4;

	lmcoord = getLmCoord();
	glcolor = gl_Color;
}