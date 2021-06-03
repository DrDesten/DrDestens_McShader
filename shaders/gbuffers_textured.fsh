#version 120

/* ////////////////////////////////////////////////////////////////////////////////////
									PARTICLES
//////////////////////////////////////////////////////////////////////////////////// */

#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	gamma(color.rgb);
	color *= texture2D(lightmap, lmcoord);
	color.rgb = color.rgb * 5;

	gl_FragData[0] = color; //gcolor
}