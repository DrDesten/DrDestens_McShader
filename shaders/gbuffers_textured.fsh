/* ////////////////////////////////////////////////////////////////////////////////////
									PARTICLES
//////////////////////////////////////////////////////////////////////////////////// */

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

/* DRAWBUFFERS:031 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	vec3 tmp   = sq(color.rgb);
	color.rgb *= getLightmap(lmcoord).rgb;
	gamma(color.rgb);

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(codeID(50), vec3(1)); // Id (SSAO Mask)
	gl_FragData[2] = vec4(0, vec3(1));  // Reflectance
}