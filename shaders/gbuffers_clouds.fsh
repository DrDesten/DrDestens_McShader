#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"

uniform float far;

#ifdef FOG
#include "/lib/sky.glsl"
#endif

in vec3 viewPos;
in vec3 playerPos;
in vec2 coord;
flat in vec3 normal;
flat in vec4 glcolor;

/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;

void main() {
	vec4 color    = getAlbedo(coord);
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
	
#ifdef FOG

	float dist = sqmag(playerPos.xz);
	float fog  = smoothstep(sq(200), sq(500), dist);
	color.rgb  = mix(color.rgb, getSky(normalize(playerPos)), fog);

#endif

	FragOut0 = color;                               // color
	FragOut1 = vec4(spheremapEncode(normal), 1, 1); // normals
	FragOut2 = vec4(codeID(52), vec3(1));           // block id (50, SSAO mask)
	FragOut3 = LIGHTING_BUF_MAX_SKY;
    ALPHA_DISCARD(FragOut0);
}