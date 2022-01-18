uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/lighting.glsl"
#include "/lib/generatePBR.glsl"

#ifdef POM_ENABLED
#ifdef POM_SMOOTH
uniform vec2  atlasSizeInverse;
uniform ivec2 atlasSize;
#endif
#endif

out float id;
out vec2  lmcoord;
out vec2  coord;
out vec4  glcolor;
out mat3  tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

/* DRAWBUFFERS:0231 */
void main() {
	vec4  albedo = getAlbedo(coord);
	albedo.rgb  *= glcolor.rgb;
	vec3  normal = tbn[2];

	MaterialInfo MatTex = FullMaterial(coord, albedo);

	float f0 = MatTex.f0;
	float emission = MatTex.emission;
	float smoothness = MatTex.roughness;
	float height = MatTex.height;
	float subsurface = MatTex.subsurface;
	float ao = MatTex.ao * glcolor.a;
	
	#ifdef WHITE_WORLD
		albedo.rgb = vec3(1);
	#endif

	#ifdef POM_ENABLED
	#ifdef POM_SMOOTH

		// Getting the Atlas Coordinates
		vec2  pcoord   = coord * atlasSize;
		vec2  interpol = fract(pcoord - 0.5);

		// Getting the in-block corrdinates to be able to wrap around
		vec2  blockcoord       = floor(pcoord * RESSOURCE_PACK_RESOLUTION_INVERSE) * RESSOURCE_PACK_RESOLUTION;
		vec2  intrablockcoord  = pcoord - blockcoord;

		// Sample All four pixel corners
		vec4 heightSamples = vec4(
			extractHeight(texelFetch(normals, ivec2(blockcoord + mod(intrablockcoord + vec2(-.5,-.5), vec2(RESSOURCE_PACK_RESOLUTION))), 0), vec4(0)),
			extractHeight(texelFetch(normals, ivec2(blockcoord + mod(intrablockcoord + vec2( .5,-.5), vec2(RESSOURCE_PACK_RESOLUTION))), 0), vec4(0)),
			extractHeight(texelFetch(normals, ivec2(blockcoord + mod(intrablockcoord + vec2(-.5, .5), vec2(RESSOURCE_PACK_RESOLUTION))), 0), vec4(0)),
			extractHeight(texelFetch(normals, ivec2(blockcoord + mod(intrablockcoord + vec2( .5, .5), vec2(RESSOURCE_PACK_RESOLUTION))), 0), vec4(0))
		);

		float heightX1 = mix(heightSamples.x, heightSamples.y, interpol.x);
		float heightX2 = mix(heightSamples.z, heightSamples.w, interpol.x);

		height = mix(heightX1, heightX2, interpol.y);


	#endif
	#endif

	gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(lmcoord, vec2(1));
	gl_FragData[3] = vec4(codeID(id), vec3(1));

	gl_FragData[4] = vec4(f0, emission, smoothness, subsurface);
	gl_FragData[5] = vec4(ao, height, vec2(1));
}

/* BUFFERSTRUCTURE /

Col0 = Albedo
Col1 = Normals
Col2 = Lightmap
Col3 = ID

Col4 = PBR: Reflectiveness+Metals, Emissive, Smoothness, SSS
Col5 = PBR: Height, AO
//////////////////*/