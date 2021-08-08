#version 120

#include "/lib/settings.glsl"
#ifdef WORLD_CURVE
#include "/lib/vertex_transform.glsl"
#endif

varying vec3 normal;

varying vec2 coord;
varying vec4 glcolor;

void main() {
	#ifdef WORLD_CURVE

		vec4 clipPos = ftransform();
		#include "/lib/world_curve.glsl"
		gl_Position = clipPos;	

	#else

		gl_Position = ftransform();

	#endif
	
	normal = normalize(gl_NormalMatrix * gl_Normal);

	coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}