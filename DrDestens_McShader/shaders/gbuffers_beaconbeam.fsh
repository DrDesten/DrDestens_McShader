#version 120

#include "/lib/math.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D texture;

varying vec3 normal;

varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:023 */
void main() {

	vec4 color = texture2D(texture, coord, 0);
	color.rgb *= glcolor.rgb * glcolor.a;
	color.rgb  = color.rgb * 1.5;
	gamma(color.rgb);


	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(50, vec3(1));
}
