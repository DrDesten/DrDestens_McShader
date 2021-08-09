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
		clipPos.xy += blue_noise_disk[int( mod(frameCounter, 64) )] * clipPos.w * screenSizeInverse * 2;
	#endif

	gl_Position = clipPos;

	coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}