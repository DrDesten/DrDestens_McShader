#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/transform.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/id.glsl"

#ifdef PBR
#include "/lib/pbr/pbr.glsl"
#include "/lib/pbr/read.glsl"
#include "/lib/pbr/ambient.glsl"
#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform vec3  sunDir;
uniform float far;
#include "/lib/sky.glsl"
#include "/lib/stars.glsl"

//////////////////////////////////////////////////////////////////////////////
//                     SKY RENDERING
//////////////////////////////////////////////////////////////////////////////

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
    float depth     = getDepth(ivec2(gl_FragCoord.xy));
    vec3  screenPos = vec3(coord, depth);
    vec3  color     = getAlbedo(ivec2(gl_FragCoord.xy));
    float id        = getID(ivec2(gl_FragCoord.xy));

#if FOG != 0
	vec3 viewPos   = toView(screenPos * 2 - 1);
	vec3 viewDir   = normalize(viewPos);
	vec3 playerPos = toPlayerEye(viewPos);
	vec3 playerDir = normalize(playerPos);

	vec3 skyGradient = getSky(playerDir);
	vec3 fogGradient = getFog(playerDir, skyGradient);
#endif
	
    if (depth == 1) { // SKY

#if FOG == 0
		vec3 viewPos   = toView(screenPos * 2 - 1);
		vec3 viewDir   = normalize(viewPos);
		vec3 playerPos = toPlayerEye(viewPos);
		vec3 playerDir = normalize(playerPos);

		vec3 skyGradient = getSky(playerDir);
#endif

#ifdef OVERWORLD

		vec4 stars  = getStars(playerDir);
		stars.a    *= saturate(abs(dot(viewDir, sunDir)) * -200 + 199);
		skyGradient = mix(skyGradient, stars.rgb, stars.a);

		color += skyGradient;

#else

		color = skyGradient;

#endif

    } else { // NO SKY

#ifdef PBR

		MaterialTexture material = getPBR(ivec2(gl_FragCoord.xy));

		color *= getAmbientLight(material.lightmap, material.ao);

#endif

#if FOG != 0

    float fog = getFogFactor(playerPos);
    color     = mix(color, fogGradient, fog);

#endif

    }
    
    FragOut0 = vec4(color, 1.0);
}