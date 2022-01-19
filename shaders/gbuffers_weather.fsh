#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;
// gbuffers_weather does not generate useful normals

/* DRAWBUFFERS:023 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lmcoord, vec2(1));
	gl_FragData[2] = vec4(codeID(3), vec3(1));
}