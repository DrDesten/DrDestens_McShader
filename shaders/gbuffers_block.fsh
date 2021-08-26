#version 120

uniform int worldTime;

#include "/lib/transform.glsl"
#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/labPBR13.glsl"
#include "/lib/lighting.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

uniform vec3 fogColor;

varying float blockId;

#ifdef PHYSICALLY_BASED
varying vec3 viewpos;
#endif
varying vec2  lmcoord;
varying vec2  coord;
varying vec4  glcolor;

varying mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

/* DRAWBUFFERS:0231 */
void main() {
	vec3  normal = tbn[2];
	float reflectiveness = 0;

	vec4 color		   = texture2D(texture, coord);
	color.rgb 		  *= glcolor.rgb;

	#ifdef PHYSICALLY_BASED

		// Get the Dafault render color, used for PBR Blending
		vec3 mc_color      = color.rgb * glcolor.a * ( texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord) );
		gamma(mc_color);

		gamma(color.rgb);
		vec3 ambientLight   = texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord);
		gamma(ambientLight);

		MaterialInfo MatTex = FullMaterial(coord, color);
		MatTex.AO 		   *= sq(glcolor.a);

		PBRout Material    = PBRMaterial(MatTex, mc_color, lmcoord, tbn, viewpos, 0.1 * ambientLight);

		color	           = Material.color;
		normal	   	       = Material.normal;
		reflectiveness     = Material.reflectiveness;

	#else

		color.rgb 		  *= glcolor.a;	
		color.rgb         *= texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord);
		gamma(color.rgb);

	#endif

	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(floor(blockId - 999.5), vec3(1));
	gl_FragData[3] = vec4(reflectiveness, vec3(1));
}