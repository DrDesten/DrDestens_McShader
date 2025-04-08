#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"

#include "/lib/pbr/gbuffers.glsl"
#include "/lib/pbr/pbr.glsl"

OPT_FLAT in vec3 normal;
OPT_FLAT in vec4 glcolor;

in vec2 coord;

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

	vec4 color = getAlbedo(coord) * glcolor;

#ifdef PBR 

	MaterialTexture materialTexture;

	vec4 normalTex       = NormalTex(coord);
	vec4 specularTex     = SpecularTex(coord);
	RawMaterial material = readMaterial(normalTex, specularTex);

	materialTexture.roughness   = material.roughness;
	materialTexture.reflectance = material.reflectance;
	materialTexture.emission    = material.emission;
	materialTexture.height      = material.height;

	color.rgb *= 2;

#else

	color.rgb *= 2;
	color.rgb  = gamma(color.rgb);

#endif

	FragOut0 = color;
	FragOut1 = vec4(spheremapEncode(normal), 1, 1);
	FragOut2 = vec4(codeID(50), vec3(1));
	FragOut3 = LIGHTING_BUF_MAX_BLOCK;
#ifdef PBR
	FragOut4 = encodeMaterial(materialTexture);
#endif
    ALPHA_DISCARD(FragOut0);
}
