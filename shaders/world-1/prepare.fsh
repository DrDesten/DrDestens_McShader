#version 150 compatibility
#extension GL_ARB_explicit_attrib_location : enable
#define NETHER
#define FRAG

#include "/core/math.glsl"
uniform vec3 fogColor;

/* DRAWBUFFERS:0 */
void main() {
	gl_FragData[0] = vec4( pow(fogColor, vec3(GAMMA)), 1 );
}