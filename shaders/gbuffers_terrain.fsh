#version 120

#include "/lib/math.glsl"
#include "/lib/lighting.glsl"
#include "/lib/gamma.glsl"

//#define PBR

uniform sampler2D lightmap;
uniform sampler2D texture;

varying vec3 viewpos;
varying vec3 normal;
varying vec2 lmcoord;
varying vec2 texcoord;
varying vec4 glcolor;

/* DRAWBUFFERS:02 */
void main() {
	vec4 color = texture2D(texture, texcoord) * glcolor;
	float dinamicLight = lmcoord.x * lmcoord.x  * 0.25;
	color.rgb  *= texture2D(lightmap, lmcoord).rgb + (dinamicLight);
	//color = glcolor;

	color.rgb = gamma(color.rgb);
		
	#ifdef PBR
		float roughness = sum((1 - color) / 3) * 0.7 + 0.3;
		vec3 BRDF = specularBRDF(color.rgb, normal, viewpos, shadowLightPosition, roughness, 0.04);
		color.rgb =  mix(BRDF, color.rgb, roughness);
	#endif
	
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
}