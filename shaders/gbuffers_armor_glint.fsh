#include "/core/math.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color     *= texture2D(lightmap, lmcoord);
	color.rgb  = gamma(color.rgb);

	FragOut0 = color; //gcolor
}