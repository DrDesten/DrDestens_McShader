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
uniform vec4 entityColor;

uniform vec3 fogColor;

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

varying vec3 viewpos;
varying vec2 lmcoord;
varying vec2 coord;

varying vec4 glcolor;

// Switch on or off Fragment based normal mapping
#ifdef FRAG_NORMALS
	flat varying vec3 N;
#else
	flat varying mat3 tbn;
	// tbn[0] = tangent vector
	// tbn[1] = binomial vector
	// tbn[2] = normal vector
#endif


/* DRAWBUFFERS:0231 */
void main() {
	#ifdef FRAG_NORMALS
	vec3  normal = N;
	#else
	vec3  normal = tbn[2];
	#endif

	float reflectiveness = 0;

	vec4 color = texture2D(texture, coord, 0);
	color.rgb *= glcolor.rgb * glcolor.a;
	color.rgb  = mix(color.rgb, entityColor.rgb, entityColor.a);

	#ifdef PHYSICALLY_BASED
		#ifdef FRAG_NORMALS
		mat3 tbn     	   = cotangentFrame(normal, -viewpos, gl_FragCoord.xy * screenSizeInverse);
		#endif

		gamma(color.rgb);
		vec3 ambientLight  = texture2D(lightmap, lmcoord).rgb;
		gamma(ambientLight);

		MaterialInfo MatTex = FullMaterial(coord, color);

		PBRout Material    = PBRMaterial(MatTex, lmcoord, tbn, viewpos, 0.1 * ambientLight + DynamicLight(lmcoord));

		color	           = Material.color;
		normal	   	       = Material.normal;
		reflectiveness     = Material.reflectiveness;

	#else

		color.rgb *= texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord);
		gamma(color.rgb);

	#endif

	gl_FragData[0] = vec4(color); //color
	gl_FragData[1] = vec4(normal, 1); //normal
	gl_FragData[2] = vec4(vec3(52), 1); //Type
	gl_FragData[3] = vec4(reflectiveness, vec3(1));
}