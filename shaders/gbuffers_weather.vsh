#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/vertex_transform_simple.glsl"
#include "/lib/kernels.glsl"

#ifdef TAA
    uniform vec2 taaOffset;
#endif

out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;

void main() {
	gl_Position = ftransform();

	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif
	
	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;
}