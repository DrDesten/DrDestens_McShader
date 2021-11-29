#version 120
#define NETHER

uniform vec3 fogColor;

/* DRAWBUFFERS:0 */
void main() {
	gl_FragData[0] = vec4( pow(fogColor, vec3(2.2)), 1 );
}