#version 120

uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/labPBR13.glsl"
#include "/lib/lighting.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform vec4 entityColor;

varying vec3 normal;
varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;


/* DRAWBUFFERS:0231 */
void main() {
	vec4 color = texture2D(texture, coord) * glcolor;
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	gamma(color.rgb);
	color *= texture2D(lightmap, lmcoord) + DynamicLight(lmcoord);

	float reflectiveness = 0;
	/* #ifdef PHYSICALLY_BASED

		PBRout Material    = PBRMaterial(coord, color, tbn, viewpos);

		color	           = Material.color;
		normal	   	       = Material.normal;
		reflectiveness     = Material.reflectiveness;

	#endif */

	gl_FragData[0] = color; //color
	gl_FragData[1] = vec4(normal, 1); //normal
	gl_FragData[2] = vec4(vec3(0), 1); //type (none = 0)
	gl_FragData[3] = vec4(reflectiveness, vec3(1));
}