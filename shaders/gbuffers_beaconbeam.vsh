#version 120

#include "/lib/settings.glsl"
#include "/lib/kernels.glsl"
#ifdef WORLD_CURVE
#include "/lib/vertex_transform.glsl"
#endif

#ifdef TAA
uniform int  frameCounter;
uniform vec2 screenSizeInverse;
#endif

varying vec3 normal;
varying vec2 coord;
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
	
	normal = normalize(gl_NormalMatrix * gl_Normal);

	coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}