#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/lib/gbuffers/color.glsl"

in vec2 coord;
flat in vec4 glcolor;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
    color.rgb  = gamma(color.rgb);

	#ifdef BLOOM
	color.rgb *= 2;
	#endif

	FragOut0 = color; //gcolor
    ALPHA_DISCARD(FragOut0);
}