uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/core/transform.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/lighting.glsl"
#include "/lib/generatePBR.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"

#include "/lib/pbr/pbr.glsl"

#ifdef POM_ENABLED
#ifdef POM_SMOOTH
    uniform vec2  atlasSizeInverse;
    uniform ivec2 atlasSize;
#endif
#endif

OPT_FLAT in mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

#ifdef PBR
    in vec3  viewpos;
#endif

flat in int blockId;
in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;

void main() {
	vec3 lightmap = vec3(lmcoord, glcolor.a);
	vec3 normal   = tbn[2];
	vec4 color    = getAlbedo(coord);
	color.rgb    *= glcolor.rgb;
	
	#ifdef WHITE_WORLD
	    color.rgb = vec3(1);
	#endif
	
	#ifdef PBR

		float roughness, reflectance, emission, height, ao;

		vec4 normalTex       = NormalTex(coord);
		vec4 specularTex     = SpecularTex(coord);
		RawMaterial material = readMaterial(normalTex, specularTex);

		roughness   = material.roughness;
		reflectance = material.reflectance;
		emission    = material.emission;
		height      = material.height;
		lightmap.z *= material.ao;

		normal      = normalize(tbn * material.normal);
/* 
		vec3 lightmapColor = getLightmap(lmcoord) + DynamicLight(lmcoord);

		// Get the Dafault render color, used for PBR Blending
		vec3 mc_color = gamma(color.rgb * glcolor.a * lightmapColor);

		color.rgb  = gamma(color.rgb);
		vec3 ambientLight   = lightmapColor;
		//gamma(ambientLight);

		MaterialInfo MatTex = FullMaterial(coord, color);
		MatTex.AO 		   *= sq(glcolor.a);

		PBRout Material     = PBRMaterial(MatTex, mc_color, lmcoord, tbn, viewpos, 0.1 * ambientLight);

		color	            = Material.color;
		normal	   	        = Material.normal;
		
		float reflectiveness = luminance(MatTex.f0);
		float roughness      = MatTex.roughness;
		float height         = MatTex.height;

		#ifdef POM_ENABLED
		#ifdef POM_SMOOTH

			// Getting the Atlas Coordinates
			vec2  pcoord   = coord * atlasSize;
			vec2  interpol = fract(pcoord - 0.5);

			// Getting the in-block corrdinates to be able to wrap around
			vec2  blockcoord       = floor(pcoord * RESOURCE_PACK_RESOLUTION_INVERSE) * RESOURCE_PACK_RESOLUTION;
			vec2  intrablockcoord  = pcoord - blockcoord;

			// Sample All four pixel corners
			vec4 heightSamples = vec4(
				extractHeight(texelFetch(normals, ivec2(blockcoord + mod(intrablockcoord + vec2(-.5,-.5), vec2(RESOURCE_PACK_RESOLUTION))), 0), vec4(0)),
				extractHeight(texelFetch(normals, ivec2(blockcoord + mod(intrablockcoord + vec2( .5,-.5), vec2(RESOURCE_PACK_RESOLUTION))), 0), vec4(0)),
				extractHeight(texelFetch(normals, ivec2(blockcoord + mod(intrablockcoord + vec2(-.5, .5), vec2(RESOURCE_PACK_RESOLUTION))), 0), vec4(0)),
				extractHeight(texelFetch(normals, ivec2(blockcoord + mod(intrablockcoord + vec2( .5, .5), vec2(RESOURCE_PACK_RESOLUTION))), 0), vec4(0))
			);

			float heightX1 = mix(heightSamples.x, heightSamples.y, interpol.x);
			float heightX2 = mix(heightSamples.z, heightSamples.w, interpol.x);

			height = mix(heightX1, heightX2, interpol.y);


		#endif
		#endif
 */
	#else

		vec3 tmp = sq(color.rgb); // Isolate unlightmapped color, else emission would depend on the lightmap

		#ifdef DIRECTIONAL_LIGHTMAP
			vec2 blockLightDir = getBlocklightDir(lightmap, mat2(tbn));
			vec3 normalMap     = extractNormal(NormalTex(coord), vec4(0));

			// Blocklight
			float blockLightShade = saturate( dot(normalMap, normalize(vec3( blockLightDir, lightmap.x ))) ) * DIRECTIONAL_LIGHTMAP_STRENGTH + (1. - DIRECTIONAL_LIGHTMAP_STRENGTH);
			lightmap.x *= saturate(1 - sq(1 - blockLightShade));
			lightmap.x += 0.03125; // Lightmap coordinates have to be at least 0.03125, else funky stuff happens		
		#endif

		color.rgb  = gamma(color.rgb);

		if (lightmap.x > 14.5/15.) {
			color.rgb = tmp * EMISSION_STRENGTH + color.rgb;
		}
		
	#endif


	FragOut0 = color;
	FragOut1 = vec4(spheremapEncode(normal), 1, 1);
	FragOut2 = vec4(codeID(blockId), vec3(1));
	FragOut3 = vec4(lightmap, 1);
    ALPHA_DISCARD(FragOut0);
}
