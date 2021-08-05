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

flat varying float blockId;
varying vec3  viewpos;
varying vec2  lmcoord;
varying vec2  coord;

varying vec4  glcolor;

flat varying mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

/* DRAWBUFFERS:0231 */
void main() {
	vec3  normal = tbn[2];
	float reflectiveness = 0;

	vec4 color		   = texture2D(texture, coord, -1) * glcolor;
	color.rgb         *= texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord);
	gamma(color.rgb);
	
	#ifdef PHYSICALLY_BASED

		PBRout Material    = PBRMaterial(coord, lmcoord, color, tbn, viewpos);

		color	           = Material.color;
		normal	   	       = Material.normal;
		reflectiveness     = Material.reflectiveness;

	#else

		if (abs(blockId - 1005) < .2) {
			color.rgb *= EMISSION_STRENGTH * .5;
		}
		
	#endif


	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(blockId - 1000, vec3(1));
	gl_FragData[3] = vec4(reflectiveness, vec3(1));
}