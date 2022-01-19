#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;
// gbuffers_weather does not generate useful normals

/* DRAWBUFFERS:03 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb *= getLightmap(lmcoord);
	gamma(color.rgb);

	color.a *= 0.5;

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(codeID(3), vec3(1));
}