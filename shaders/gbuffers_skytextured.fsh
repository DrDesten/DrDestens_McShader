#include "/lib/settings.glsl"
#include "/lib/math.glsl"

uniform sampler2D texture;

in vec2 coord;
in vec4 glcolor;

/* DRAWBUFFERS:0 */

void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;

	gl_FragData[0] = color; //gcolor
}