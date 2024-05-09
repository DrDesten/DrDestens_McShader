uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/lighting.glsl"

uniform vec3 fogColor;

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
/* DRAWBUFFERS:0123 */
#else
/* DRAWBUFFERS:012 */
#endif

layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;

void main() {
	vec3 normal = tbn[2];

	vec4 color = texture2D(texture, coord);
	color.rgb *= glcolor.rgb;

	#ifdef WHITE_WORLD
	    color.rgb = vec3(1);
	#endif

	#ifdef PBR

		// Get the Dafault render color, used for PBR Blending
		vec3 mc_color       = gamma( color.rgb * glcolor.a * ( getLightmap(lmcoord).rgb + DynamicLight(lmcoord) ) );

		color.rgb           = gamma(color.rgb);
		vec3 ambientLight   = getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
		//gamma(ambientLight);

		MaterialInfo MatTex = FullMaterial(coord, color);
		MatTex.AO 		   *= sq(glcolor.a);

		PBRout Material    = PBRMaterial(MatTex, mc_color, lmcoord, tbn, viewpos, 0.1 * ambientLight);

		color	           = Material.color;
		normal	   	       = Material.normal;

		float reflectiveness = luminance(MatTex.f0);
		float roughness      = MatTex.roughness;
		float height         = MatTex.height;

	#else

		color.rgb *= glcolor.a;	
		color.rgb *= getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
		color.rgb  = gamma(color.rgb);

	#endif

	FragOut0 = color;
	FragOut1 = vec4(normal, 1);
	FragOut2 = vec4(codeID(blockId), vec3(1));
	#ifdef PBR
	FragOut3 = vec4(roughness, reflectiveness, 0, height);
	#endif
    ALPHA_DISCARD(FragOut0);
}