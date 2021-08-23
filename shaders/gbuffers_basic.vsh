#version 120

#include "/lib/settings.glsl"
#include "/lib/vertex_transform.glsl"
#include "/lib/kernels.glsl"

#ifdef TAA
uniform int  frameCounter;
uniform vec2 screenSizeInverse;
#endif

varying vec2 lmcoord;
varying vec4 glcolor;

void main() {
	vec4 clipPos = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif
	
	#ifdef TAA
		clipPos.xy += TAAOffsets[int( mod(frameCounter, 6) )] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif

	gl_Position = clipPos;

	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
}