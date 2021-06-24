#version 120

#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec3 normal;
varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:024 */
void main() {
	vec4 color = texture2D(texture, coord) * glcolor;
	gamma(color.rgb);
	color *= texture2D(lightmap, lmcoord);


	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(normal, 1); //normal
	gl_FragData[2] = vec4(vec3(0), 1); //type (none = 0)
}