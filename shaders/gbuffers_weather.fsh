#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"


in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;
// gbuffers_weather does not generate useful normals

/* uniform vec2 screenSizeInverse;
uniform sampler2D colortex4; */

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb *= getLightmap(lmcoord);
	color.rgb  = gamma(color.rgb);

	//color.a *= 0.5;
	//color.a   = sqrt(color.a);
	//color.a = 1;

	/* vec3 bloomColor = texture2D(texture, gl_FragCoord.xy * screenSizeInverse * 0.5).rgb;
	color.rgb = bloomColor;
	//color.rgb = (gl_FragCoord.xy * screenSizeInverse).rgg;
 */
	gl_FragData[0] = color; //gcolor
}