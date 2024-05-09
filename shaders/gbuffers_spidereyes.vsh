#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/vertex_transform_simple.glsl"
#include "/core/kernels.glsl"

#ifdef TAA
 uniform vec2 taaOffset;
#endif

out vec2 coord;
out vec4 glcolor;

void main() {
	gl_Position = ftransform();

	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif

	coord   = getCoord();
	glcolor = gl_Color;
}