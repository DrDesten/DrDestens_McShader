

#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
// gbuffers_weather does not generate normals

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color 	  *= texture2D(lightmap, lmcoord);
	gamma(color.rgb);

	color.a *= 0.5;

	gl_FragData[0] = color; //gcolor
	//gl_FragData[1] = vec4(vec3(0), 1); //normals
	//gl_FragData[1] = vec4(vec3(0), 1); //set type to water
}