uniform int worldTime;
//uniform vec2 atlasSizeInverse;

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/generatePBR.glsl"
#include "/lib/lighting.glsl"

#include "/core/water.glsl"

uniform float frameTimeCounter;

#ifdef OPTIMIZE_INTERPOLATION
    flat in mat3 tbn;
#else
    in mat3 tbn;
#endif
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

flat in int blockId;
in vec3 worldPos;
in vec3 viewDir;
in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

vec3 noiseNormals(vec2 coord, float strength) {
    vec2  e = vec2(0.01, 0);
    float C = fbm(coord,        2);
    float R = fbm(coord + e.xy, 2);
    float B = fbm(coord + e.yx, 2);

    vec3 n  = vec3(R-C, B-C, e.x);
    n.xy   *= strength;
    return normalize(n);
}

#ifndef PHYSICALLY_BASED
/* DRAWBUFFERS:023 */
#else
#ifdef PHYSICALLY_BASED
/* DRAWBUFFERS:0231 */
#else
/* DRAWBUFFERS:023 */
#endif
#endif

void main(){
    vec3  surfaceNormal  = tbn[2];
	vec4  color          = texture2D(texture, coord, 0) * vec4(glcolor.rgb, 1);

    #ifdef PHYSICALLY_BASED
    float reflectiveness, roughness = 0;
    #endif

    // Reduce opacity and saturation of only water
    if (blockId == 10) {

        #ifdef WATER_TEXTURE_VISIBLE
         color.rgb = sq(color.rgb * getLightmap(lmcoord).rgb) * 0.75;
        #else

            color.rgb          = vec3(0);
            color.a            = 0.01;

        #endif

        #ifdef WATER_NORMALS

            float surfaceDot   = dot(viewDir, surfaceNormal);
            
            // "Fake" Waves
            vec2  seed         = (worldPos.xz * WATER_NORMALS_SIZE) + (frameTimeCounter * 0.5);
            float blend        = saturate(map(abs(surfaceDot), 0.005, 0.2, 0.05, 1));              // Reducing the normals at small angles to avoid high noise
            //vec3  noiseNormals = noiseNormals(seed, WATER_NORMALS_AMOUNT * 0.1 * blend);
            vec3  noiseNormals = waterNormalsSine(worldPos, frameTimeCounter);

            surfaceNormal      = normalize(tbn * noiseNormals);
            //surfaceNormal      = noiseNormals;

        #endif

    } else {

        #ifdef PHYSICALLY_BASED

		    // Get the Dafault render color, used for PBR Blending
            vec3 mc_color = gamma(color.rgb * glcolor.a * ( getLightmap(lmcoord).rgb + DynamicLight(lmcoord) ));
            color.rgb     = gamma(color.rgb);

            vec3 ambientLight  = getLightmap(lmcoord).rgb;

		    MaterialInfo MatTex = FullMaterial(coord, color);
            MatTex.AO 		   *= sq(glcolor.a);

            PBRout Material    = PBRMaterial(MatTex, mc_color, lmcoord, tbn, viewDir, 0.1 * ambientLight + DynamicLight(lmcoord));

            color	           = Material.color;
            surfaceNormal      = Material.normal;
            
            reflectiveness = luminance(MatTex.f0);
            roughness      = MatTex.roughness;

        #else

            #ifdef WHITE_WORLD
            color.rgb = vec3(1);
            #endif

	        color.rgb         *= glcolor.a;
            color.rgb         *= getLightmap(lmcoord).rgb + DynamicLight(lmcoord);
            color.rgb  = gamma(color.rgb);

        #endif

    }

    
    gl_FragData[0] = color; // Color
    //gl_FragData[0] = vec4(surfaceNormal, 1); // Color
    //gl_FragData[0] = vec4(surfaceNormal * .5 + .5, 1); // Color
    gl_FragData[1] = vec4(surfaceNormal, 1); // Normal
    gl_FragData[2] = vec4(codeID(blockId), vec3(1)); // Type (colortex3)
    #ifdef PHYSICALLY_BASED
    gl_FragData[3] = vec4(reflectiveness, vec3(1));
    #endif
}