/* ////////////////////////////////////////////////////////////////////////////////////
									PARTICLES
//////////////////////////////////////////////////////////////////////////////////// */

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

#ifdef PBR
/* DRAWBUFFERS:023 */
#else
/* DRAWBUFFERS:02 */
#endif

layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;

void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb *= getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
	color.rgb  = gamma(color.rgb);

	FragOut0 = color; //gcolor
	FragOut1 = vec4(codeID(50), vec3(1)); // Id (SSAO Mask)
	#ifdef PBR
	FragOut2 = PBR_EMPTY; // pbr
	#endif
    ALPHA_DISCARD(FragOut0);
}