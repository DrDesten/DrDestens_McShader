#version 120

#include "/lib/settings.glsl"
#include "/lib/vertex_transform.glsl"

varying vec2 lmcoord;
varying vec4 glcolor;

void main() {
	vec4 clipPos = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif

	gl_Position = clipPos;

	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
}