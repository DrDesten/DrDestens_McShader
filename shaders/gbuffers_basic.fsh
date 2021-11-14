#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D lightmap;

#if SELECTION_OUTLINE != 0
 uniform int   renderStage;
#endif
#if SELECTION_OUTLINE == 2
 uniform float frameTimeCounter;
 uniform vec2  screenSizeInverse;
#endif

varying vec2 lmcoord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {

	vec4 color = vec4(glcolor.rgb, step(0.01, glcolor.a));
	color     *= texture2D(lightmap, lmcoord);

	#if SELECTION_OUTLINE != 0

		#if MC_VERSION >= 11605
		if (renderStage == MC_RENDER_STAGE_OUTLINE) {
		#else
		if (abs(glcolor.a - 0.5) < 0.2) {
		#endif

			#if SELECTION_OUTLINE == 1
				color.rgb = vec3(1.5);
			#else
				color.rgb = cos( (frameTimeCounter + (gl_FragCoord.xy * screenSizeInverse).xyx + vec3(2, 0, 4)) ) + 0.5;
			#endif
		}

	#endif


	gamma(color.rgb);

	gl_FragData[0] = color; //gcolor
	
}