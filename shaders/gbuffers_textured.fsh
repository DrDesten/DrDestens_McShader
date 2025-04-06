/* ////////////////////////////////////////////////////////////////////////////////////
									PARTICLES
//////////////////////////////////////////////////////////////////////////////////// */

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

#if FOG != 0
uniform float frameTimeCounter;
uniform float far;
#include "/lib/sky.glsl"
in vec3 playerPos;
#endif

/* DRAWBUFFERS:023 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;

void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb  = gamma(color.rgb);

#if FOG != 0

    float fog = getFogFactor(playerPos);
    color.rgb = mix(color.rgb, getFog(normalize(playerPos)), fog);

#endif

	FragOut0 = color; //gcolor
	FragOut1 = vec4(codeID(50), vec3(1)); // Id (SSAO Mask)
	FragOut2 = vec4(lmcoord, glcolor.a, 0);
    ALPHA_DISCARD(FragOut0);
}