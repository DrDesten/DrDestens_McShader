uniform int worldTime;

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/lighting.glsl"

uniform vec4 entityColor;

uniform vec3 fogColor;

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

#ifdef OPTIMIZE_INTERPOLATION
    flat in vec4 glcolor;

    // Switch on or off Fragment based normal mapping
    #ifdef FRAG_NORMALS
        flat in vec3 N;
    #else
        flat in mat3 tbn;
    #endif
#else
    in vec4 glcolor;

    // Switch on or off Fragment based normal mapping
    #ifdef FRAG_NORMALS
        in vec3 N;
    #else
        in mat3 tbn;
    #endif
#endif
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

#ifdef PHYSICALLY_BASED
    in vec3 viewpos;
#endif

in vec2 lmcoord;
in vec2 coord;

#ifdef PHYSICALLY_BASED
/* DRAWBUFFERS:0231 */
#else
/* DRAWBUFFERS:023 */
#endif
void main() {
	#ifdef FRAG_NORMALS
	vec3  normal = N;
	#else
	vec3  normal = tbn[2];
	#endif

	vec4 color = texture2D(texture, coord, 0) * glcolor;
	color.rgb  = mix(color.rgb, entityColor.rgb, entityColor.a);
	
	#ifdef WHITE_WORLD
	    color.rgb = vec3(1);
	#endif

	#ifdef PHYSICALLY_BASED

		// Get the Dafault render color, used for PBR Blending
		vec3 mc_color      = color.rgb * ( getLightmap(lmcoord).rgb + DynamicLight(lmcoord) );
		gamma(mc_color);

		#ifdef FRAG_NORMALS
		mat3 tbn     	   = cotangentFrame(normal, -viewpos, gl_FragCoord.xy * screenSizeInverse);
		#endif

		color.rgb  = gamma(color.rgb);
		vec3 ambientLight  = getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
		//gamma(ambientLight);

		MaterialInfo MatTex = FullMaterial(coord, color);
		//MatTex.AO 		   *= sq(glcolor.a);

		PBRout Material    = PBRMaterial(MatTex, mc_color, lmcoord, tbn, viewpos, 0.1 * ambientLight);

		color	           = Material.color;
		normal	   	       = Material.normal;
		
		float reflectiveness = luminance(MatTex.f0);
		float roughness      = MatTex.roughness;
		float height         = MatTex.height;

	#else

		color.rgb *= getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
		color.rgb  = gamma(color.rgb);

	#endif

	gl_FragData[0] = vec4(color); //color
	gl_FragData[1] = vec4(normal, 1); //normal
	gl_FragData[2] = vec4(codeID(54), vec3(1)); //Type
	#ifdef PHYSICALLY_BASED
	gl_FragData[3] = vec4(reflectiveness, height, vec2(1));
	#endif
}