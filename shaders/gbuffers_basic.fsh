#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

#if SELECTION_OUTLINE != 0
 uniform int   renderStage;
#endif
#if SELECTION_OUTLINE == 2
 uniform float frameTimeCounter;
 uniform vec2  screenSizeInverse;
#endif

in vec2 lmcoord;
in vec4 glcolor;

/* DRAWBUFFERS:03 */
void main() {
	vec4 color = vec4(glcolor.rgb, fstep(0.01, glcolor.a));
	color.rgb *= getLightmap(lmcoord);

	#if SELECTION_OUTLINE != 0

		#if MC_VERSION >= 11605
		if (renderStage == MC_RENDER_STAGE_OUTLINE) {
		#else
		if (abs(glcolor.a - 0.5) < 0.2) { // Workaround for detecting the block outline in versions prior to 1.16.5
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
	gl_FragData[1] = vec4(codeID(3), vec3(1)); //gcolor
}