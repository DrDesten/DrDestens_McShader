#version 120

uniform int worldTime;

#include "/lib/transform.glsl"
#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/labPBR13.glsl"
#include "/lib/lighting.glsl"
#include "/lib/generatePBR.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

uniform vec3 fogColor;
uniform vec2 atlasSizeInverse;

varying float blockId;
#ifdef PHYSICALLY_BASED
varying vec3  viewpos;
#endif
varying vec2  lmcoord;
varying vec2  coord;

varying vec4  glcolor;

varying mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

#ifdef PARALLAX_OCCLUSION
 #ifdef PHYSICALLY_BASED
  /* DRAWBUFFERS:02314 */
 #else
  /* DRAWBUFFERS:0231 */
 #endif
#else
 /* DRAWBUFFERS:0231 */
#endif
void main() {
	vec3  normal         = tbn[2];
	float reflectiveness = 0;
	float height 		 = 1;
	float id		     = floor(blockId + 0.5);

	vec4 color		   = texture2D(texture, coord, 0) * vec4(glcolor.rgb, 1);
	
	#ifdef WHITE_WORLD
	color.rgb = vec3(1);
	#endif
	
	#ifdef PHYSICALLY_BASED

		// Get the Dafault render color, used for PBR Blending
		vec3 mc_color = color.rgb * glcolor.a * ( texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord) );
		gamma(mc_color);

		gamma(color.rgb);
		vec3 ambientLight   = texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord);
		gamma(ambientLight);

		MaterialInfo MatTex = FullMaterial(coord, color);
		MatTex.AO 		   *= sq(glcolor.a);

		/* vec3 baseColor = texture2D(texture, coord).rgb;
		vec3 heights = vec3(
			sum(texture2D(texture, coord, -2).rgb) * 0.333,
			sum(texture2D(texture, coord + vec2(atlasSizeInverse.x, 0), -2).rgb) * 0.333,
			sum(texture2D(texture, coord + vec2(0, atlasSizeInverse.y), -2).rgb) * 0.333
		);

		MatTex.normal       = generateNormals(heights, 1);
		MatTex.roughness    = generateRoughness(baseColor);
		MatTex.f0           = vec3(0.04); */

		PBRout Material     = PBRMaterial(MatTex, mc_color, lmcoord, tbn, viewpos, 0.1 * ambientLight);

		color	            = Material.color;
		normal	   	        = Material.normal;
		reflectiveness      = Material.reflectiveness;
		height 				= MatTex.height;

	#else

		color.rgb 		  *= glcolor.a;
		color.rgb         *= texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord);
		gamma(color.rgb);

		if (id == 1005) {
			color.rgb *= EMISSION_STRENGTH * .5;
		}
		
	#endif

	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(id - 1000, vec3(1));
	gl_FragData[3] = vec4(reflectiveness, height, vec2(1));
	
	#ifdef PARALLAX_OCCLUSION
	#ifdef PHYSICALLY_BASED
	gl_FragData[4] = vec4(tbn[2] * 0.5 + 0.5, 1); // Since the Bloom Buffer is only in use in composite5/6, I can use it for POM
	#endif
	#endif
}
