#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
// gbuffers_weather does not generate useful normals

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb *= getLightmap(lmcoord);
	gamma(color.rgb);

	color.a *= 0.5;

	gl_FragData[0] = color; //gcolor
}