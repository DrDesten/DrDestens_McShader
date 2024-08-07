uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/lighting.glsl"

#include "/lib/pbr/pbr.glsl"

uniform vec4 entityColor;

uniform vec3 fogColor;

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

OPT_FLAT in vec4 glcolor;

// Switch on or off Fragment based normal mapping
#ifdef FRAG_NORMALS
	OPT_FLAT in vec3 N;
#else
	OPT_FLAT in mat3 tbn;
#endif
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

#ifdef PBR
    in vec3 viewpos;
#endif

in vec2 lmcoord;
in vec2 coord;

#ifdef PBR
/* DRAWBUFFERS:0123 */
#else
/* DRAWBUFFERS:012 */
#endif

layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;

void main() {
	#ifdef FRAG_NORMALS
	vec3  normal = N;
	#else
	vec3  normal = tbn[2];
	#endif

	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb  = mix(color.rgb, entityColor.rgb, entityColor.a);
	
	#ifdef WHITE_WORLD
	    color.rgb = vec3(1);
	#endif

	#ifdef PBR
	
		#ifdef FRAG_NORMALS
		mat3 tbn = cotangentFrame(normal, -viewpos, gl_FragCoord.xy * screenSizeInverse);
		#endif

		float roughness, reflectance, emission, height, ao;
		vec2  lightmap;

		vec4 normalTex       = NormalTex(coord);
		vec4 specularTex     = SpecularTex(coord);
		RawMaterial material = readMaterial(normalTex, specularTex);

		roughness   = material.roughness;
		reflectance = material.reflectance;
		emission    = material.emission;
		height      = material.height;
		ao          = material.ao;
		lightmap    = lmcoord;

		normal      = normalize(tbn * material.normal);

	#else

		color.rgb *= getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
		color.rgb  = gamma(color.rgb);

	#endif

	FragOut0 = color; //color
	FragOut1 = vec4(spheremapEncode(normal), 1, 1); //normal
	FragOut2 = vec4(codeID(54), vec3(1)); //Type
	#ifdef PBR
	FragOut3 = encodeMaterial(
		MaterialTexture(
			roughness, 
			reflectance, 
			emission, 
			height, 
			ao, 
			lightmap
		), ivec2(gl_FragCoord.xy)
	);
	#endif
    ALPHA_DISCARD(FragOut0); 
}