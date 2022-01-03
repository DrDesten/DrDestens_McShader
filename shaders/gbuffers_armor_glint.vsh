

#include "/lib/settings.glsl"
#include "/lib/vertex_transform_simple.glsl"
#include "/lib/kernels.glsl"

#ifdef TAA
uniform int  frameCounter;
uniform vec2 screenSizeInverse;
#endif

out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;

void main() {
	vec4 clipPos = ftransform();

	#ifdef TAA
		clipPos.xy += TAAOffsets[int( mod(frameCounter, 9) )] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif

	gl_Position = clipPos;
	
	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;
}