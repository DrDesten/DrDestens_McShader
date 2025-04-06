#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/transform.glsl"
#include "/core/debug.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/id.glsl"
#include "/lib/composite/lightmap.glsl"

#ifdef PBR
#include "/lib/composite/normal.glsl"
#include "/lib/pbr/pbr.glsl"
#include "/lib/pbr/read.glsl"
#include "/lib/pbr/lighting.glsl"
#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float frameTimeCounter;
uniform float far;
#include "/lib/sky.glsl"
#include "/lib/stars.glsl"
#include "/lib/lightmap.glsl"

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

		vec3 lightmap      = getLightmapData(ivec2(gl_FragCoord.xy));
		vec3 lightmapColor = getCustomLightmap(lightmap, customLightmapBlend);

#ifdef PBR

	#if FOG == 0
		vec3 viewPos   = toView(screenPos * 2 - 1);
		vec3 viewDir   = normalize(viewPos);
	#endif

		vec3 normal = getNormal(ivec2(gl_FragCoord.xy));

		MaterialTexture matTex   = getPBR(ivec2(gl_FragCoord.xy));
		Material        material = getMaterial(matTex, lightmap, color);
		
		vec3 PBRColor = RenderPBR(material, normal, viewDir, lightmapColor);
		color.rgb     = PBRColor;

#else 

		color.rgb *= lightmapColor;

#endif

#if FOG != 0

    float fog = getFogFactor(playerPos);
    color     = mix(color, fogGradient, fog);

#endif

    }

	/* vec4 chart = BarChart(coord, 
		vec3(0, 1, daynight),
		vec3(0, 1, customLightmapBlend)
	);
	color.rgb = mix(color.rgb, chart.rgb, chart.a); */
    
    FragOut0 = vec4(color, 1.0);
}