#version 120

uniform int worldTime;

#include "/lib/math.glsl"
#include "/lib/lighting.glsl"
#include "/lib/labPBR.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec3 viewpos;
varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

varying mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

/* DRAWBUFFERS:02 */
void main() {
	vec4 color = texture2D(texture, coord) * glcolor;
	gamma(color.rgb);
	
	float dinamicLight = lmcoord.x * lmcoord.x  * 0.25;
	color.rgb  *= texture2D(lightmap, lmcoord).rgb + (dinamicLight);
		
	#ifdef PBR
		vec3 lightPos = lightPosition();

		vec4 normalTex	 = NormalTex(coord);
		vec3 normalMap   = normalize(tbn * extractNormal(normalTex));


		vec4 specularTex = SpecularTex(coord);
		float roughness  = extractRoughness(specularTex);
		float f0 		 = extractF0(specularTex);

		vec3 BRDF;
		BRDF = specularBRDF(color.rgb, normalMap, viewpos, lightPos, roughness, f0);

		// Blend between normal mc rendering and PBR rendering
		color *= 0.8;
		color.rgb = mix(color.rgb, BRDF, clamp(f0 + .25, 0, .85));
	#endif

	
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(tbn[2], 1);
}