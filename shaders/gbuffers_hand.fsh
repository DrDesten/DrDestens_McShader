

uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/lighting.glsl"

uniform vec3 fogColor;

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

#ifdef PHYSICALLY_BASED
varying vec3  viewpos;
#endif
varying vec2  lmcoord;
varying vec2  coord;

varying vec4  glcolor;

// Switch on or off Fragment based normal mapping
#ifdef FRAG_NORMALS
	varying vec3 N;
#else
	varying mat3 tbn;
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
	
	vec4 color = texture2D(texture, coord, 0) * glcolor;

	#ifdef PHYSICALLY_BASED

		// Get the Dafault render color, used for PBR Blending
		vec3 mc_color      = color.rgb * ( texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord) );
		gamma(mc_color);

		#ifdef FRAG_NORMALS
		mat3 tbn     	   = cotangentFrame(normal, -viewpos, gl_FragCoord.xy * screenSizeInverse);
		#endif

		gamma(color.rgb);
		vec3 ambientLight  = texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord);
		//gamma(ambientLight);

		MaterialInfo MatTex = FullMaterial(coord, color);
		//MatTex.AO 		   *= sq(glcolor.a);

		PBRout Material    = PBRMaterial(MatTex, mc_color, lmcoord, tbn, viewpos, 0.1 * ambientLight);

		color	           = Material.color;
		normal	   	       = Material.normal;
		reflectiveness     = Material.reflectiveness;
		
		reflectiveness += Bayer4(gl_FragCoord.xy) * (1./255) - (0.5/255);
    	reflectiveness = smoothCutoff(reflectiveness, SSR_REFLECTION_THRESHOLD, 0.5);

	#else

		color.rgb         *= texture2D(lightmap, lmcoord).rgb + DynamicLight(lmcoord);
		gamma(color.rgb);

	#endif

	//color.a = min(0.01, color.a);

	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(codeID(51), vec3(1));
	gl_FragData[3] = vec4(reflectiveness, vec3(1));
}