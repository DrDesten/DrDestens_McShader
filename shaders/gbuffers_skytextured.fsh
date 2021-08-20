#version 120

#include "/lib/gamma.glsl"

uniform sampler2D texture;

varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */

void main() {
	vec4 color = texture2D(texture, coord, 0);
	color.rgb *= glcolor.rgb * glcolor.a;

	color.rgb *= 1 + (0.5 * float(color.r > 0.5));
	
    gamma(color.rgb);

	gl_FragData[0] = color; //gcolor
}