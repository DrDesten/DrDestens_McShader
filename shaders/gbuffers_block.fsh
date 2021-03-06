

uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/lighting.glsl"

uniform vec3 fogColor;

in float blockId;

#ifdef PHYSICALLY_BASED
in vec3 viewpos;
#endif
in vec2  lmcoord;
in vec2  coord;
in vec4  glcolor;

in mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

/* DRAWBUFFERS:0231 */
void main() {
	vec3  normal         = tbn[2];
	float reflectiveness = 0;
	float height 		 = 1;

	vec4 color		   = texture2D(texture, coord);
	color.rgb 		  *= glcolor.rgb;

	#ifdef WHITE_WORLD
	 color.rgb = vec3(1);
	#endif

	#ifdef PHYSICALLY_BASED

		// Get the Dafault render color, used for PBR Blending
		vec3 mc_color       = color.rgb * glcolor.a * ( getLightmap(lmcoord).rgb + DynamicLight(lmcoord) );
		gamma(mc_color);

		gamma(color.rgb);
		vec3 ambientLight   = getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
		//gamma(ambientLight);

		MaterialInfo MatTex = FullMaterial(coord, color);
		MatTex.AO 		   *= sq(glcolor.a);

		PBRout Material    = PBRMaterial(MatTex, mc_color, lmcoord, tbn, viewpos, 0.1 * ambientLight);

		color	           = Material.color;
		normal	   	       = Material.normal;
		reflectiveness     = Material.reflectiveness;
		height             = MatTex.height;
		
		reflectiveness += Bayer4(gl_FragCoord.xy) * (1./255) - (0.5/255);
    	reflectiveness = smoothCutoff(reflectiveness, SSR_REFLECTION_THRESHOLD, 0.5);

	#else

		color.rgb 		  *= glcolor.a;	
		color.rgb         *= getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
		gamma(color.rgb);

	#endif

	gl_FragData[0] = color;
	gl_FragData[1] = vec4(normal, 1);
	gl_FragData[2] = vec4(codeID(blockId), vec3(1));
	gl_FragData[3] = vec4(reflectiveness, height, vec2(1));
}