#include "/lib/uniforms/lighting.glsl"

const vec3 lightmapDay                = vec3(LIGHTMAP_SKY_DAY_R, LIGHTMAP_SKY_DAY_G, LIGHTMAP_SKY_DAY_B);
const vec3 lightmapNight              = vec3(LIGHTMAP_SKY_NIGHT_R, LIGHTMAP_SKY_NIGHT_G, LIGHTMAP_SKY_NIGHT_B);
const vec3 lightmapBlock              = vec3(LIGHTMAP_BLOCK_R, LIGHTMAP_BLOCK_G, LIGHTMAP_BLOCK_B);
const vec3 lightmapComplexBlockBright = vec3(LIGHTMAP_COMPLEX_BLOCK_BRIGHT_R, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_G, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_B);
const vec3 lightmapComplexBlockDark   = vec3(LIGHTMAP_COMPLEX_BLOCK_DARK_R, LIGHTMAP_COMPLEX_BLOCK_DARK_G, LIGHTMAP_COMPLEX_BLOCK_DARK_B);

const vec3 lightmapEnd    = vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B) * 0.5 + vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B) * 0.5;
vec3       lightmapNether = mix(fogColor, vec3(1,.4,.3), 0.5);

vec3 mixLightmap(vec3 lightmap /* lmcoord (xy) + AO (z) */, vec3 skyLight, vec3 blockLight) {
    // Skylight
    skyLight *= (
        lightmap.y * lightmap.y                                              
        #if LIGHTMAP_SKYLIGHT_AO != 100
        #if LIGHTMAP_SKYLIGHT_AO <= 100
        * (lightmap.z * lightmap_skylight_ao + (1. - lightmap_skylight_ao)) // Skylight AO
        #else
        * pow(lightmap.z, lightmap_skylight_ao)
        #endif
        #else
        * lightmap.z
        #endif
    );
    // Blocklight
    blockLight *= (
        saturate(lightmap.x * lightmap.x * 1.1)                                  
        #if LIGHTMAP_BLOCKLIGHT_AO != 100
        #if LIGHTMAP_BLOCKLIGHT_AO <= 100
        * (lightmap.z * lightmap_blocklight_ao + (1. - lightmap_blocklight_ao)) // Blocklight AO
        #else
        * pow(lightmap.z, lightmap_blocklight_ao)
        #endif
        #else
        * lightmap.z
        #endif
    );

    skyLight   = mix(skyLight,   skyLight,  nightVision * (1 - lightmap.y));
    blockLight = mix(blockLight, blockLight, nightVision * (1 - lightmap.y));
    
    float caveLight = LIGHTMAP_MINIMUM_LIGHT * (lightmap.y * (lightmap.y - 2) + 1) * lightmap.z;
    return blockLight + skyLight + caveLight;
}

vec3 getCustomLightmap(vec3 lightmap /* lmcoord + AO */, float customLightmapBlend) {
    #ifndef LIGHTMAP_COMPLEX_BLOCKLIGHT
        const vec3 blocklightColor = lightmapBlock;
    #else
        #if LIGHTMAP_COMPLEX_BLOCKLIGHT_BLEND_CURVE != 50
            float blocklightColorBlend = pow(lightmap.x, lightmap_complex_blocklight_blend_curve);
            vec3  blocklightColor = mix(lightmapComplexBlockDark, lightmapComplexBlockBright, blocklightColorBlend);
        #else
            vec3  blocklightColor = mix(lightmapComplexBlockDark, lightmapComplexBlockBright, lightmap.x);
        #endif
        #if MC_VERSION >= 11900
            if (darknessFactor > 0) {

                blocklightColor *= sqsq(lightmap.x);
                float timeOszillator  = sin(frameTimeCounter) * 0.5 + .5;
                float lightOszillator = sin(lightmap.x * 15 + (frameTimeCounter * 2));
                float glitter         = saturate(lightOszillator * 500 - 495);

                vec3 darknessBlocklight = sqsq( saturate(lightOszillator) ) * mix( vec3(0.4,1.0,1.7), vec3(0.0, 0.8, 0.2),  timeOszillator);
                darknessBlocklight      = mix(darknessBlocklight, vec3(1), glitter);

                blocklightColor += darknessBlocklight * darknessFactor;
                lightmap.x = saturate(lightmap.x + lightmap.x * glitter);

                lightmap.x *= timeOszillator * 0.5 + 0.5;
                lightmap.y *= timeOszillator;

            }
        #endif
    #endif

    #if LIGHTMAP_SKYLIGHT_CONTRAST != 50
    lightmap.y = pow(lightmap.y, lightmap_skylight_contrast);
    #endif
    #if LIGHTMAP_BLOCKLIGHT_CONTRAST != 50
    lightmap.x = pow(lightmap.x, lightmap_blocklight_contrast);
    #endif

    #ifdef NETHER
    vec3 skyLight = (lightmapNether / maxc(lightmapNether));
    lightmap.y     = LIGHTMAP_NETHER_SKY_BRIGHTNESS;
    #elif defined END
    vec3 skyLight = applySaturation(lightmapEnd / maxc(lightmapEnd), LIGHTMAP_END_SKY_SATURATION);
    lightmap.y     = LIGHTMAP_END_SKY_BRIGHTNESS;
    #else
    vec3 skyLight = mix(lightmapNight, lightmapDay, customLightmapBlend);
    #endif
    
    return mixLightmap(lightmap, skyLight, blocklightColor);
}