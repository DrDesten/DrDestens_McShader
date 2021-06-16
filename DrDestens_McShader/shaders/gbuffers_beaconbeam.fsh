#version 120

uniform sampler2D texture;

varying vec2 coord;
varying vec4 glcolor;

void main() {
	vec4 color = texture2D(texture, coord) * glcolor;

/* DRAWBUFFERS:0 */
	gl_FragData[0] = color; //gcolor
}