uniform int worldTime;
//uniform vec2 atlasSizeInverse;

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/generatePBR.glsl"
#include "/lib/lighting.glsl"

#include "/core/water.glsl"

uniform float frameTimeCounter;

OPT_FLAT in mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

flat in int blockId;
in vec3 worldPos;
in vec3 viewDir;
in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

#ifdef PBR
/* DRAWBUFFERS:0123 */
#else
/* DRAWBUFFERS:012 */
#endif

layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;

void main(){
    vec3  surfaceNormal  = tbn[2];
	vec4  color          = texture2D(texture, coord, 0) * vec4(glcolor.rgb, 1);

    #ifdef PBR
    float reflectiveness, roughness = 0;
    #endif

    // Reduce opacity and saturation of only water
    if (blockId == 10) {

        #ifdef WATER_TEXTURE_VISIBLE
            color.rgb = sq(color.rgb * getLightmap(lmcoord).rgb) * 0.75;
        #else
            color.rgb          = vec3(0);
            color.a            = PI;
        #endif

        #if WATER_NORMALS != 0
            float surfaceDot   = dot(viewDir, surfaceNormal);

            #if WATER_NORMALS == 1
                vec2  seed        = (worldPos.xz * WATER_NORMALS_SIZE) + (frameTimeCounter * 0.5);
                float blend       = saturate(map(abs(surfaceDot), 0.005, 0.2, 0.05, 1));
                vec3  waveNormals = noiseNormals(seed, WATER_NORMALS_AMOUNT * 0.1 * blend);
            #else 
                float blend       = saturate(-surfaceDot * 3);
                vec3  waveNormals = waterNormalsSine(worldPos, frameTimeCounter, WATER_NORMALS_AMOUNT * blend);
            #endif

            surfaceNormal      = normalize(tbn * waveNormals);
            //surfaceNormal      = noiseNormals;
        #endif

    } else {

        #ifdef PBR

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

    
    FragOut0 = color; // Color
    //FragOut0 = vec4(surfaceNormal, 1); // Color
    //FragOut0 = vec4(surfaceNormal * .5 + .5, 1); // Color
    FragOut1 = vec4(surfaceNormal, 1); // Normal
    FragOut2 = vec4(codeID(blockId), vec3(1)); // Type (colortex3)
    #ifdef PBR
    FragOut3 = vec4(roughness, reflectiveness, 0, 1);
    #endif
    if (FragOut0.a != PI) {
        ALPHA_DISCARD(FragOut0);
    } else {
        FragOut0.a = 0;
    }
}