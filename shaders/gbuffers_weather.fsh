#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"

#if RAIN_DETECTION_MODE == 0
    uniform float temperature;
#endif

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;
// gbuffers_weather does not generate useful normals

/* DRAWBUFFERS:03 */
void main() {
	vec4 color = texture2D(texture, coord, 0) * glcolor;

#if RAIN_DETECTION_MODE == 0
	bool isRain = temperature >= 0.15;                                 // Rain (detected based on player temperature)
#elif RAIN_DETECTION_MODE == 1
	vec3 normalizedColor = normalize(color.rgb);
	bool isRain          = saturate((color.b) - avg(color.rg)) > 0.25; // Rain (detected based on blue dominance)
#endif

	float rain = 0;
	if (isRain) {
		rain    = float(color.a > 0.01);
		color.a = rain * RAIN_OPACITY;
	}
	
	color.rgb *= getLightmap(lmcoord);
	color.rgb  = gamma(color.rgb);

	gl_FragData[0] = color; //gcolor
	gl_FragData[1] = vec4(vec3(codeID(rain * 53)), 1); //gcolor
}