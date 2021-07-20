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

uniform float viewHeight;
uniform float viewWidth;

flat varying float blockId;
varying vec3  viewpos;
varying vec2  lmcoord;
varying vec2  coord;

varying vec4  glcolor;

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
	
	vec4 color		   = texture2D(texture, coord) * glcolor;
	gamma(color.rgb);
	color.rgb         *= texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord);

	#ifdef PHYSICALLY_BASED
		#ifdef FRAG_NORMALS
		mat3 tbn     	   = cotangentFrame(normal, -viewpos, gl_FragCoord.xy / vec2(viewWidth, viewHeight));
		#endif

		PBRout Material    = PBRMaterial(coord, lmcoord, color, tbn, viewpos);

		color	           = Material.color;
		normal	   	       = Material.normal;
		reflectiveness     = Material.reflectiveness;

	#endif

	//color.a = min(0.01, color.a);

	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(51, vec3(1));
	gl_FragData[3] = vec4(reflectiveness, vec3(1));
}