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

		vec4 stars  = getStars(playerPos, playerDir);
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

        if (depth < 1) { // NOT SKY

        #if FOG == 1

            float dist = length(viewPos);

            #ifdef SUNSET_FOG
            #ifdef OVERWORLD
                dist = dist * (sunset * SUNSET_FOG_AMOUNT + 1);
            #endif
            #endif

            #if defined END
                float fog       = 1 - exp(min(dist * (15e-3 * -FOG_AMOUNT) + 0.1, 0));
            #elif defined NETHER
                float fog       = 1 - exp(min(dist * (9e-3 * -FOG_AMOUNT) + 0.1, 0));
            #else
                float fog       = 1 - exp(min(dist * (2e-3 * -FOG_AMOUNT) + 0.1, 0));
            #endif

            fog = 2 * sq(fog) / (1 + fog); // Make a smooth transition

        #else

            const float fogStart = 0.5 / max(FOG_AMOUNT, 0.6);
            const float fogEnd   = 1.0;

            float dist = length(playerPos * vec3(1,0.1,1));
            #if defined SUNSET_FOG && defined OVERWORLD
            // if it is a cloud, apply set fog distances as they don't depend on render distance (cloud id is 52)
            float fog  = id == 52 ? smoothstep(200, 300, dist) : smoothstep(far * fogStart * (-sunset * (SUNSET_FOG_AMOUNT / 10) + 1), far, dist);
            #else
            float fog  = id == 52 ? smoothstep(200, 300, dist) : smoothstep(far * fogStart, far, dist);
            #endif

        #endif

        color = mix(color, fogGradient, fog);

        }

#endif

    }
    
    FragOut0 = vec4(color, 1.0);
}