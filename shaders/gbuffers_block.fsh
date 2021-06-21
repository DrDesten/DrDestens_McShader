#version 120

#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying float blockId;
varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = texture2D(texture, coord) * glcolor;
	gamma(color.rgb);
	color *= texture2D(lightmap, lmcoord);

	
	if (blockId == 1005) {
		color.rgb = vec3(2);
	}

	gl_FragData[0] = color; //gcolor
}