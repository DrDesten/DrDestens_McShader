#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"

#include "/lib/gbuffers/color.glsl"
#include "/lib/gbuffers/lightmap.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color     *= texture(lightmap, lmcoord);
	color.rgb  = gamma(color.rgb);

	FragOut0 = color; //gcolor
    ALPHA_DISCARD(FragOut0);
}