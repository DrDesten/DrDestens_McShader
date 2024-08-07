#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"

OPT_FLAT in vec3 normal;
OPT_FLAT in vec4 glcolor;

in vec2 coord;

#ifdef PBR
/* DRAWBUFFERS:0123 */
#else
/* DRAWBUFFERS:012 */
#endif

layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;

void main() {

	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb *= 2;
	color.rgb  = gamma(color.rgb);


	FragOut0 = color;
	FragOut1 = vec4(spheremapEncode(normal), 1, 1);
	FragOut2 = vec4(codeID(50), vec3(1));
	#ifdef PBR
	FragOut3 = PBR_EMPTY; // no pbr
	#endif
    ALPHA_DISCARD(FragOut0);
}
