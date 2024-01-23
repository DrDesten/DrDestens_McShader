#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"

uniform float rainStrength;
uniform vec3  fogColor;

uniform float lightBrightness;
uniform vec3  lightPosition;

in vec3 viewPos;
in vec2 coord;
flat in vec3 normal;
flat in vec4 glcolor;

#ifdef PBR
/* DRAWBUFFERS:0123 */
#else
/* DRAWBUFFERS:012 */
#endif

layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;

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
	color.a    = fstep(0.5, color.a);

	color.rgb = mix(color.rgb, fogColor * 0.1, rainStrength); // Weather Stuff

	FragOut0 = color;                     // color
	FragOut1 = vec4(normal, 1);           // normals
	FragOut2 = vec4(codeID(52), vec3(1)); // block id (50, SSAO mask)
	#ifdef PBR
	FragOut3 = vec4(1, 0, 0, 1);
	#endif
    ALPHA_DISCARD(FragOut0);
}