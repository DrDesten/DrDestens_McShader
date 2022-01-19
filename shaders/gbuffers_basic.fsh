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

/* DRAWBUFFERS:023 */
void main() {
	vec4 color = vec4(glcolor.rgb, fstep(0.01, glcolor.a));

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(lmcoord, vec2(1)); //gcolor
	gl_FragData[2] = vec4(codeID(3), vec3(1)); //gcolor
}