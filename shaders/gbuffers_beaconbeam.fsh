#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"


#ifdef OPTIMIZE_INTERPOLATION
    flat in vec3 normal;
    flat in vec4 glcolor;
#else
    in vec3 normal;
    in vec4 glcolor;
#endif

in vec2 coord;

#ifdef PHYSICALLY_BASED
/* DRAWBUFFERS:0231 */
#else
/* DRAWBUFFERS:023 */
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
	FragOut1 = vec4(normal, 1);
	FragOut2 = vec4(codeID(50), vec3(1));
	#ifdef PHYSICALLY_BASED
	FragOut3 = PBR_EMPTY; // no pbr
	#endif
    ALPHA_DISCARD(FragOut0);
}
