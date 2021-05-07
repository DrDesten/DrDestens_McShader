#version 120

#include "/lib/math.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	float dinamicLight = lmcoord.x * lmcoord.x  * lmcoord.x;
	color.rgb  *= texture2D(lightmap, lmcoord).rgb + (dinamicLight);
	//color = glcolor;

	gl_FragData[0] = color;
}