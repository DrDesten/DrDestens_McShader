#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

#ifdef WORLD_CURVE
 #include "/lib/vertex_transform.glsl"
#else
 #include "/lib/vertex_transform_simple.glsl"
#endif

#ifdef TAA
 uniform vec2 taaOffset;
 uniform vec2 screenSizeInverse;
#endif

out vec3 normal;
out vec2 coord;
out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif
	
	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * screenSizeInverse * 2;
	#endif
	
	normal  = getNormal();
	coord   = getCoord();
	glcolor = gl_Color;
}