#include "/lib/settings.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D texture;

varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */

void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;

	#ifdef OVERWORLD
	 #ifdef BLOOM
	  color.rgb *= 1 + (float(color.r > 0.5));
	 #endif
	#endif
	
    gamma(color.rgb);

	gl_FragData[0] = color; //gcolor
}