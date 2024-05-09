#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

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

OPT_FLAT out vec3 normal;
OPT_FLAT out vec4 glcolor;
out vec2 coord;

void main() {
	gl_Position = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif
	
	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif
	
	normal  = getNormal();
	coord   = getCoord();
	glcolor = gl_Color;
}