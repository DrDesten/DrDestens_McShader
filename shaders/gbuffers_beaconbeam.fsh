#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec3 normal;
in vec2 coord;
in vec4 glcolor;

#ifdef PHYSICALLY_BASED
/* DRAWBUFFERS:0231 */
#else
/* DRAWBUFFERS:023 */
#endif
void main() {

	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb *= 2;
	color.rgb  = gamma(color.rgb);


	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(codeID(50), vec3(1));
	#ifdef PHYSICALLY_BASED
	gl_FragData[3] = PBR_EMPTY; // no pbr
	#endif
}
