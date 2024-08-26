#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"

#if FOG != 0
uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float far;
#include "/lib/sky.glsl"
in vec3 playerPos;
#endif

#if RAIN_DETECTION_MODE == 0
    uniform float temperature;
#endif

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;
// gbuffers_weather does not generate useful normals

/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 FragOut0;

void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;

#if RAIN_DETECTION_MODE == 0
	bool isRain = temperature >= 0.15;                                 // Rain (detected based on player temperature)
#elif RAIN_DETECTION_MODE == 1
	vec3 normalizedColor = normalize(color.rgb);
	bool isRain          = saturate((color.b) - avg(color.rg)) > 0.25; // Rain (detected based on blue dominance)
#endif

	color.rgb *= getLightmap(lmcoord);

#if FOG != 0
	color.a *= 1 - getFogFactor(playerPos);
#endif

	FragOut0 = color; //gcolor
    ALPHA_DISCARD(FragOut0);
}