uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/generatePBR.glsl"

#ifdef POM_ENABLED
#ifdef POM_SMOOTH
uniform vec2  atlasSizeInverse;
uniform ivec2 atlasSize;
#endif
#endif

in float id;
in vec2  lmcoord;
in vec2  coord;
in vec4  glcolor;
in mat3  tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

/* DRAWBUFFERS:012345 */
void main() {
	vec4  albedo = getAlbedo(coord);
	albedo.rgb  *= glcolor.rgb;

	MaterialInfo MatTex = FullMaterial(coord, albedo);

	float f0 = MatTex.f0;
	float emission = MatTex.emission;
	float smoothness = MatTex.roughness;
	float height = MatTex.height;
	float subsurface = MatTex.subsurface;
	float ao = MatTex.ao * glcolor.a;

	vec3  normal = tbn * MatTex.normal;
	
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

	vec2 blockLightDir = getBlocklightDir(lmcoord, mat2(tbn));
	vec2 newlm         = lmcoord;
	// Blocklight
	float blockLightShade = saturate( dot(MatTex.normal, normalize(vec3( blockLightDir, lmcoord.x ))) ) * DIRECTIONAL_LIGHTMAP_STRENGTH + (1. - DIRECTIONAL_LIGHTMAP_STRENGTH);
	newlm.x *= saturate(1 - sq(1 - blockLightShade));


	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(normal, 1);
	#ifdef ADVANCED_MATERIALS
	gl_FragData[2] = vec4(lmcoord, vec2(1));
	#else
	gl_FragData[2] = vec4(newlm, glcolor.a, 1);
	#endif
	gl_FragData[3] = vec4(codeID(id), vec3(1));

	gl_FragData[4] = vec4(f0, emission, smoothness, subsurface);
	gl_FragData[5] = vec4(height, ao, vec2(1));
}


/* BUFFERSTRUCTURE /

Col0 = Albedo
Col1 = Normals
Col2 = Lightmap
Col3 = ID

Col4 = PBR: Reflectiveness+Metals, Emissive, Smoothness, SSS
Col5 = PBR: Height, AO

//////////////////*/