#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/vertex_transform_simple.glsl"
#include "/lib/kernels.glsl"

#ifdef TAA
 uniform int  taaIndex;
 uniform vec2 screenSizeInverse;
#endif

out vec2 coord;
out vec3 normal;
out vec3 viewPos;
out vec4 glcolor;

void main() {
	vec4 clipPos = ftransform();

	#ifdef TAA
		clipPos.xy += TAAOffsets[taaIndex] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif
	
	gl_Position = clipPos;
	
	normal  = getNormal();
	viewPos = getView();
	coord   = getCoord();
	glcolor = gl_Color;
}