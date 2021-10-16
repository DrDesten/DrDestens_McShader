#version 120
#define NETHER

uniform vec3 fogColor;

/* DRAWBUFFERS:0 */
void main() {
	gl_FragData[0] = vec4( pow(fogColor * 0, vec3(2.2)), 1 );
}