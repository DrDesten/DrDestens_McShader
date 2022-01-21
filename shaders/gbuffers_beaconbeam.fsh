#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 coord;
in vec4 glcolor;

/* DRAWBUFFERS:03 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb  = gamma(color.rgb);
	color.rgb *= 2;


	gl_FragData[0] = color;
	gl_FragData[1] = vec4(codeID(3), vec3(1));
}
