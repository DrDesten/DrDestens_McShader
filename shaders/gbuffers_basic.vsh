#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/kernels.glsl"

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