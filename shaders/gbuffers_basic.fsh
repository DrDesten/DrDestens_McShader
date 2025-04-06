#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/lightmap.glsl"

uniform int renderStage;

#if SELECTION_OUTLINE == 2
    uniform float frameTimeCounter;
    uniform vec2  screenSizeInverse;
#endif

in vec2 lmcoord;
in vec4 glcolor;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
	vec4 color = vec4(glcolor.rgb, fstep(0.01, glcolor.a));
	color.rgb *= getLightmap(lmcoord);
		
	bool isBlockOutline;
	#if SUPPORTS_RENDERSTAGE
	isBlockOutline = renderStage == MC_RENDER_STAGE_OUTLINE;
	#else
	isBlockOutline = abs(glcolor.a - 0.5) < 0.2; // Workaround for detecting the block outline in versions prior to 1.16.5
	#endif

	if (isBlockOutline) {
	#if SELECTION_OUTLINE == 0
		color.rgb = vec3(0);
	#elif SELECTION_OUTLINE == 1
		color.rgb = vec3(1.5);
	#elif SELECTION_OUTLINE == 2
		color.rgb = cos( (frameTimeCounter + (gl_FragCoord.xy * screenSizeInverse).xyx + vec3(2, 0, 4)) ) + 0.5;
	#endif
		color.a = SELECTION_OUTLINE_OPACITY;
	}

	color.rgb  = gamma(color.rgb);

	FragOut0 = color; //gcolor
    ALPHA_DISCARD(FragOut0);
}