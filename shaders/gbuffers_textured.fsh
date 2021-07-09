#version 120

/* ////////////////////////////////////////////////////////////////////////////////////
									PARTICLES
//////////////////////////////////////////////////////////////////////////////////// */

#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:031 */
void main() {
	vec4 color = texture2D(texture, coord) * glcolor;
	gamma(color.rgb);
	color.rgb *= texture2D(lightmap, lmcoord).rgb;
	color.rgb  = color.rgb * 5;

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(0, vec3(1)); // Id
	gl_FragData[2] = vec4(0, vec3(1)); // Reflectance
}