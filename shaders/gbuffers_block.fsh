uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"

#include "/lib/pbr/gbuffers.glsl"
#include "/lib/pbr/pbr.glsl"

OPT_FLAT in vec4  glcolor;
OPT_FLAT in mat3  tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

#ifdef PBR
    in vec3 viewpos;
#endif

flat in int blockId;
in vec2 lmcoord;
in vec2 coord;

#ifdef PBR
/* DRAWBUFFERS:01237 */
#else
/* DRAWBUFFERS:0123 */
#endif

layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;
layout(location = 4) out vec4 FragOut4;

void main() {
	vec3 lightmap = vec3(lmcoord, glcolor.a);
	vec3 normal   = tbn[2];
	vec4 color    = getAlbedo(coord);
	color.rgb    *= glcolor.rgb;

	#ifdef WHITE_WORLD
	    color.rgb = vec3(1);
	#endif

	#ifdef PBR

		float roughness, reflectance, emission, height;

		vec4 normalTex       = NormalTex(coord);
		vec4 specularTex     = SpecularTex(coord);
		RawMaterial material = readMaterial(normalTex, specularTex);

		roughness   = material.roughness;
		reflectance = material.reflectance;
		emission    = material.emission;
		height      = material.height;
		lightmap.z *= material.ao;

		normal      = normalize(tbn * material.normal);

	#else

		color.rgb  = gamma(color.rgb);

	#endif

	FragOut0 = color;
	FragOut1 = vec4(spheremapEncode(normal), 1, 1);
	FragOut2 = vec4(codeID(blockId), vec3(1));
	FragOut3 = vec4(lightmap, 1);
    ALPHA_DISCARD(FragOut0);
}