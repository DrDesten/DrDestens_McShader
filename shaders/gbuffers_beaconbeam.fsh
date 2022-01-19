

#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec3 normal;
in vec2 coord;
in vec4 glcolor;

/* DRAWBUFFERS:03 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb *= 2;
	gamma(color.rgb);


	gl_FragData[0] = color;
	gl_FragData[1] = vec4(codeID(3), vec3(1));
}
