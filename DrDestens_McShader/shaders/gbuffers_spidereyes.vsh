#version 120

#include "/lib/settings.glsl"
#include "/lib/kernels.glsl"

uniform int  frameCounter;
uniform vec2 screenSizeInverse;

varying vec2 coord;
varying vec4 glcolor;

void main() {
	vec4 clipPos = ftransform();

	#ifdef TAA
		clipPos.xy += TAAOffsets[int( mod(frameCounter, 8) )] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif

	gl_Position = clipPos;

	coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}