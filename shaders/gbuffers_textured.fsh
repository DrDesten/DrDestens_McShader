/* ////////////////////////////////////////////////////////////////////////////////////
									PARTICLES
//////////////////////////////////////////////////////////////////////////////////// */

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

#ifdef PHYSICALLY_BASED
/* DRAWBUFFERS:031 */
#else
/* DRAWBUFFERS:03 */
#endif
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb *= getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
	color.rgb  = gamma(color.rgb);

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(codeID(50), vec3(1)); // Id (SSAO Mask)
	#ifdef PHYSICALLY_BASED
	gl_FragData[2] = PBR_EMPTY; // pbr
	#endif
}