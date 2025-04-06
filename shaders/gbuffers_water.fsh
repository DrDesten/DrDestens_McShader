uniform int worldTime;
uniform float frameTimeCounter;
//uniform vec2 atlasSizeInverse;

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/lib/pbr/gbuffers.glsl"
#include "/lib/pbr/pbr.glsl"
#include "/lib/pbr/lighting.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"
#include "/lib/lightmap.glsl"

#include "/core/water.glsl"

uniform vec3 cameraPosition;

uniform float far;

#ifdef FOG
#include "/lib/sky.glsl"
#endif

OPT_FLAT in mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

flat in int blockId;
in vec3 viewDir;
in vec3 playerPos;
in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

#ifdef PBR
/* DRAWBUFFERS:01237 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;
layout(location = 4) out vec4 FragOut4;
#else
/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;
#endif

void main(){
    vec3  lightmap       = vec3(lmcoord, glcolor.a);
    vec3  surfaceNormal  = tbn[2];
	vec4  color          = getAlbedo(coord);
    color.rgb           *= glcolor.rgb;

    #ifdef PBR
    MaterialTexture tex;
    #endif

    // Reduce opacity and saturation of only water
    if (blockId == 10) {

        #ifdef WATER_TEXTURE_VISIBLE
            color.rgb = sq(color.rgb * getLightmap(lmcoord).rgb) * 0.75;
        #else
            color.rgb          = vec3(0);
            color.a            = 0;
        #endif

        #if WATER_NORMALS != 0
            vec3  worldPos   = playerPos + cameraPosition;
            float surfaceDot = dot(viewDir, surfaceNormal);

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

        vec3 lightmapColor = getCustomLightmap(lightmap, customLightmapBlend);

        #ifdef PBR

            vec4 normalTex       = NormalTex(coord);
            vec4 specularTex     = SpecularTex(coord);
            RawMaterial raw = readMaterial(normalTex, specularTex);

            tex.roughness   = raw.roughness;
            tex.reflectance = raw.reflectance;
            tex.emission    = raw.emission;
            tex.height      = raw.height;
            lightmap.z     *= raw.ao;

            Material material = getMaterial(raw, lightmap, color.rgb);
            
            vec3 PBRColor = RenderPBR(material, surfaceNormal, viewDir, lightmapColor);
            color.rgb     = PBRColor;

        #else

            #ifdef WHITE_WORLD
            color.rgb = vec3(1);
            #endif

            color.rgb  = gamma(color.rgb);
            color.rgb *= lightmapColor;

        #endif

    }

#if FOG != 0

    float fog = getFogFactor(playerPos);
    color.rgb = mix(color.rgb, getFog(normalize(playerPos)), fog);

#endif
    
    FragOut0 = color; // Color
    FragOut1 = vec4(spheremapEncode(surfaceNormal), 1, 1); // Normal
    FragOut2 = vec4(codeID(blockId), vec3(1)); // Type 
	FragOut3 = vec4(lightmap, 1);
#ifdef PBR
	FragOut4 = encodeMaterial(tex);
#endif
}