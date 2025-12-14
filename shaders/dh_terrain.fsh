
#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/core/transform.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"
#include "/lib/pbr/gbuffers.glsl"
#include "/lib/pbr/pbr.glsl"

#include "/core/dh/discard.glsl"

flat in vec3 normal;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 worldPos;
flat in int materialId;

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

void main() {
    bool isCloud =  worldPos.y > 400; 
#ifdef DH_TERRAIN_DISCARD
    if ( !isCloud && discardDHDithered(backToPlayer(worldPos), gl_FragCoord.xy) ) {
        discard;
    }
#endif
    
	vec3  lightmap     = vec3(lmcoord, glcolor.a);
    vec4  color        = vec4(glcolor.rgb, 1);

    if ( !isCloud ) {

        // Noise Shaping
        float baseScale   = 1; 
        float octaveScale = 2;
        float octaveDecay = 1.5;

        float valueShift = 0.9;
        float valueScale = 0.25;

        switch (materialId) {
            case DH_BLOCK_LEAVES: { // All types of leaves, bamboo, or cactus
                baseScale   = 2;
                octaveDecay = 1.5;
                valueShift  = 0.75;
                valueScale  = 1.;
            } break;
            case DH_BLOCK_STONE: { // Stone or ore
            
            } break;
            case DH_BLOCK_WOOD: { // Any wooden item
            
            } break;
            case DH_BLOCK_METAL: { // Any block that emits a metal or copper sound
            
            } break;
            case DH_BLOCK_DIRT: { // Dirt, grass, podzol, and coarse dirt
                valueShift = 0.8;
                valueScale = 0.5;
            } break;
            case DH_BLOCK_LAVA: { // Lava
                octaveDecay = 1.5;
                valueShift  = 0.6;
                valueScale  = 0.8;
            } break;
            case DH_BLOCK_DEEPSLATE: { // Deepslate
            
            } break;
            case DH_BLOCK_SNOW: { // Snow
                baseScale   = 0.25;
                valueShift  = 0.95;
                valueScale  = 0.1;
            } break;
            case DH_BLOCK_SAND: { // Sand and red sand
                baseScale   = 1;
                octaveDecay = 2;
                valueShift  = 1;
                valueScale  = 0.3;
            } break;
            case DH_BLOCK_TERRACOTTA: { // Terracotta
                valueScale  = 0.1;
            } break;
            case DH_BLOCK_NETHER_STONE: { // Blocks that have the "base_stone_nether" tag
                octaveDecay = 2;
                valueShift  = 0.8;
                valueScale  = 0.4;
            } break;
        }

        float texelDensity = max(
            maxc(abs(dFdx(worldPos))),
            maxc(abs(dFdy(worldPos)))
        );

        float idealScale = (1./8) * baseScale / texelDensity;
        float scale      = clamp(exp2(round(log2(idealScale))), 0, 4);
        vec3  globalRef  = fract(worldPos / 1024) * 1024;

        float dhNoise = 0;
        float tw      = 0;
        float w       = 1;
        for (float i = 0; i < 3; i++) {
            vec3 seed = floor(globalRef * scale + 2e-3) / scale;
        
            dhNoise  += rand(seed) * w;

            scale    *= octaveScale;
            w        *= octaveDecay;
            tw       += w; 
        }
        dhNoise /= tw;
        dhNoise  = (dhNoise * valueScale + valueShift);

        color.rgb *= dhNoise;

    }

#ifdef PBR

    MaterialTexture material;
    material.roughness = 0.8;
    material.reflectance = 0.0;
    material.height = 1.0;
    material.emission = 0.0;

    if (materialId == DH_BLOCK_LAVA) {
        material.emission = 1.0;
    }

#else 

    color.rgb = gamma(color.rgb);

#endif

    if (lightmap.x > 14.5/15.) {
        color.rgb *= ( 1 + EMISSION_STRENGTH );
    }

	FragOut0 = color;
	FragOut1 = vec4(spheremapEncode(normal), 1, 1);
	FragOut2 = vec4(codeID(0), vec3(1));
	FragOut3 = vec4(lightmap, 1);
#ifdef PBR
	FragOut4 = encodeMaterial(material);
#endif
}