#include "/lib/math.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color     *= texture2D(lightmap, lmcoord);
	gamma(color.rgb);

	gl_FragData[0] = color; //gcolor
}