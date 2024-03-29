uniform int worldTime;

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/transform.glsl"
#include "/core/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/lighting.glsl"
#include "/lib/generatePBR.glsl"

#ifdef POM_ENABLED
#ifdef POM_SMOOTH
    uniform vec2  atlasSizeInverse;
    uniform ivec2 atlasSize;
#endif
#endif


#ifdef OPTIMIZE_INTERPOLATION
    flat in mat3 tbn;
#else
    in mat3 tbn;
#endif
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

#ifdef PHYSICALLY_BASED
    in vec3  viewpos;
#endif

flat in int blockId;
in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

#ifdef PHYSICALLY_BASED
/* DRAWBUFFERS:0231 */
#else
/* DRAWBUFFERS:023 */
#endif

layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;

void main() {
	vec3  normal = tbn[2];

	vec4 color = texture2D(texture, coord, 0);
	color.rgb *= glcolor.rgb;
	
	#ifdef WHITE_WORLD
	    color.rgb = vec3(1);
	#endif
	
	#ifdef PHYSICALLY_BASED

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

	#else

		vec3 tmp = sq(color.rgb); // Isolate unlightmapped color, else emission would depend on the lightmap

		#ifdef DIRECTIONAL_LIGHTMAP
			vec2 blockLightDir = getBlocklightDir(lmcoord, mat2(tbn));
			vec3 normalMap     = extractNormal(NormalTex(coord), vec4(0));
			vec2 newlm         = lmcoord;

			// Blocklight
			float blockLightShade = saturate( dot(normalMap, normalize(vec3( blockLightDir, lmcoord.x ))) ) * DIRECTIONAL_LIGHTMAP_STRENGTH + (1. - DIRECTIONAL_LIGHTMAP_STRENGTH);
			newlm.x *= saturate(1 - sq(1 - blockLightShade));
			newlm.x += 0.03125; // Lightmap coordinates have to be at least 0.03125, else funky stuff happens

			color.rgb *= getLightmap(newlm) + DynamicLight(newlm);
		#else
			color.rgb *= getLightmap(lmcoord) + DynamicLight(lmcoord);
		#endif

		color.rgb *= glcolor.a;
		color.rgb  = gamma(color.rgb);

		if (lmcoord.x > 14.5/15.) {
			color.rgb = tmp * EMISSION_STRENGTH + color.rgb;
		}
		
	#endif


	FragOut0 = color;
	FragOut1 = vec4(normal, 1);
	FragOut2 = vec4(codeID(blockId), vec3(1));
	#ifdef PHYSICALLY_BASED
	FragOut3 = vec4(reflectiveness, height, vec2(1));
	#endif
    ALPHA_DISCARD(FragOut0);
}
