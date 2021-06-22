#version 120

uniform int worldTime;

#include "/lib/transform.glsl"
#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/lighting.glsl"
#include "/lib/labPBR13.glsl"
#include "/lib/gamma.glsl"

uniform ivec2 atlasSize;

uniform sampler2D lightmap;
uniform sampler2D texture;

varying float blockId;
varying vec3 viewpos;
varying vec2 lmcoord;
varying vec2 coord;
varying vec2 mid_coord;
varying vec4 glcolor;

varying mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

/* DRAWBUFFERS:0234 */
void main() {
	vec3 normal = tbn[2];
		
	#ifdef PBR
		/* float height 	 = extractHeight(NormalTex(coord));
		vec3 playerPos	 = toPlayerEye(viewpos);
		vec3 viewDir 	 = tbn * normalize(viewpos);
		viewDir			*= (1 - height) * 0.01; */

		vec2 newcoord 	 = coord;
		
		vec2 spriteSize  = 2.0 * atlasSize * abs(coord - mid_coord.xy);

		vec4 color		= texture2D(texture, newcoord) * glcolor;
		gamma(color.rgb);
		float dinamicLight = lmcoord.x * lmcoord.x  * 0.25;
		color.rgb  *= texture2D(lightmap, lmcoord).rgb + (dinamicLight);


		//////////////////// PBR /////////////////////////////////////

		vec3 lightPos	 = lightPosition();

		vec4 normalTex	 = NormalTex(newcoord);
		vec4 specularTex = SpecularTex(newcoord);

		#ifdef HEIGHT_AO
		color.rgb 		*= extractHeight(normalTex, specularTex);
		#endif
		normal           = normalize(tbn * extractNormal(normalTex, specularTex));
		float AO 		 = extractAO(normalTex, specularTex);

		float roughness  = extractRoughness(normalTex, specularTex);
		float f0 		 = extractF0(normalTex, specularTex);
		if (f0 > (230/255)) {f0 = 1;} // Metals
		float emission   = extractEmission(normalTex, specularTex);

		vec4 BRDF;
		color.rgb 		*= AO;
		color.rgb 		*= emission * 10 + 1;
		BRDF			 = specularBRDF(color.rgb, normal, viewpos, lightPos, roughness, f0) * (float(lightPos == sunPosition) * 0.9 + 0.1); //Reduce brightness at night

		color.rgb 		*= 0.8;

		// Blend between normal MC rendering and PBR rendering
		float blend  = clamp(f0 + PBR_BLEND_MIN, 0, PBR_BLEND_MAX);
		color.rgb 	 = mix(color.rgb, BRDF.rgb, blend);
		BRDF.a 		 = mix(0, BRDF.a, blend);

	#else 

		vec4 color = texture2D(texture, coord) * glcolor;
		gamma(color.rgb);
		
		float dinamicLight = lmcoord.x * lmcoord.x  * 0.25;
		color.rgb  *= texture2D(lightmap, lmcoord).rgb + (dinamicLight);

	#endif

	if (blockId == 1005) {
		color.rgb *= 4;
	}

	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[3] = vec4(vec3(blockId - 1000), 1);
}