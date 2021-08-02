#version 120

#include "/lib/math.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D texture;

varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {

	vec4 color = texture2D(texture, coord) * glcolor;
	color.rgb  = color.rgb * 1.5;
	gamma(color.rgb);


	gl_FragData[0] = color;
}
