/* ////////////////////////////////////////////////////////////////////////////////////
									PARTICLES
//////////////////////////////////////////////////////////////////////////////////// */

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"

#include "/lib/pbr/gbuffers.glsl"
#include "/lib/pbr/pbr.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

#if FOG != 0
uniform float frameTimeCounter;
uniform float far;
#include "/lib/sky.glsl"
in vec3 playerPos;
#endif

#ifdef PBR
/* DRAWBUFFERS:01237 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;
layout(location = 4) out vec4 FragOut4;
#else
/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;
#endif

void main() {
	vec3 lightmap = vec3(lmcoord, 1);
	vec4 color    = getAlbedo(coord) * glcolor;
	vec3 normal   = vec3(0,0,1);
	
#ifdef PBR

	MaterialTexture materialTexture;

	vec4 normalTex       = NormalTex(coord);
	vec4 specularTex     = SpecularTex(coord);
	RawMaterial material = readMaterial(normalTex, specularTex);

	materialTexture.roughness   = material.roughness;
	materialTexture.reflectance = material.reflectance;
	materialTexture.emission    = material.emission;
	materialTexture.height      = material.height;
	lightmap.z                 *= material.ao;

	normal = material.normal;

#else

	color.rgb = gamma(color.rgb);

#endif

#if FOG != 0

    float fog = getFogFactor(playerPos);
    color.rgb = mix(color.rgb, getFog(normalize(playerPos)), fog);

#endif

	FragOut0 = color; //gcolor
	FragOut1 = vec4(spheremapEncode(normal), 1, 1);
	FragOut2 = vec4(codeID(50), vec3(1)); // Id (SSAO Mask)
	FragOut3 = vec4(lightmap, 0);
#ifdef PBR
	FragOut4 = encodeMaterial(materialTexture);
#endif
    ALPHA_DISCARD(FragOut0);
}