/* ////////////////////////////////////////////////////////////////////////////////////
									PARTICLES
//////////////////////////////////////////////////////////////////////////////////// */

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/lighting_basics.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

/* DRAWBUFFERS:03 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb *= getLightmap(lmcoord, 1);
    color.rgb  = gamma(color.rgb);

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(codeID(3), vec3(1));
}