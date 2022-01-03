#version 130
#define NETHER

#include "/lib/math.glsl"
uniform vec3 fogColor;

/* DRAWBUFFERS:0 */
void main() {
	gl_FragData[0] = vec4( pow(fogColor, vec3(GAMMA)), 1 );
}