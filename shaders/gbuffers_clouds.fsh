#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform float rainStrength;
uniform vec3  fogColor;

uniform float lightBrightness;
uniform vec3  lightPosition;

in vec2 coord;
in vec3 normal;
in vec3 viewPos;
in vec4 glcolor;

/* DRAWBUFFERS:03 */
void main() {
	vec4 color    = texture2D(texture, coord);
	vec3 lightPos = normalize(lightPosition);

	// "Volumetrics" (not actually)
	float passThroughAngle = saturate(dot(normalize(viewPos), lightPos));
	float vol_1 = passThroughAngle * 0.2 + 0.8;
	float vol_2 = sq(sq(passThroughAngle));

	// diffuse
	float diffuse = clamp(dot(normal, lightPos), 0, 1);

	color.rgb *= glcolor.rgb * (1 - sq(1 - lightBrightness));
	color.rgb *= (diffuse + 0.75) * (vol_1 + vol_2);
	color.a   *= vol_1 * 0.5 + 0.5;

	color.rgb = mix(color.rgb, fogColor * 0.1, rainStrength); // Weather Stuff

	gl_FragData[0] = color;
	gl_FragData[3] = vec4(codeID(3), vec3(1));
}