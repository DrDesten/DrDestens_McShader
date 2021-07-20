#version 120

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:03 */
void main() {
	vec4 color = texture2D(texture, coord) * glcolor;
	color *= texture2D(lightmap, lmcoord);

	color.a *= 0.01;

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(1); //set type to water
}