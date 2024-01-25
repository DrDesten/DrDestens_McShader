uniform float nightVision;
uniform float darknessFactor;

const vec3 lightmapDay                = vec3(LIGHTMAP_SKY_DAY_R, LIGHTMAP_SKY_DAY_G, LIGHTMAP_SKY_DAY_B);
const vec3 lightmapNight              = vec3(LIGHTMAP_SKY_NIGHT_R, LIGHTMAP_SKY_NIGHT_G, LIGHTMAP_SKY_NIGHT_B);
const vec3 lightmapComplexBlockBright = vec3(LIGHTMAP_COMPLEX_BLOCK_BRIGHT_R, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_G, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_B);
const vec3 lightmapComplexBlockDark   = vec3(LIGHTMAP_COMPLEX_BLOCK_DARK_R, LIGHTMAP_COMPLEX_BLOCK_DARK_G, LIGHTMAP_COMPLEX_BLOCK_DARK_B);

const vec3 lightmapEnd    = vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B) * 0.5 + vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B) * 0.5;
const vec3 lightmapNether = vec3(1,.4,.3);

vec3 mixLightmap(vec3 lmcoord /* lmcoord (xy) + AO (z) */, vec3 skyLight, vec3 blockLight) {

    skyLight *= (
        lmcoord.y * lmcoord.y                                              // Skylight
        #if LIGHTMAP_SKYLIGHT_AO != 100
        * (lmcoord.z * lightmap_skylight_ao + (1. - lightmap_skylight_ao)) // Skylight AO
        #else
        * lmcoord.z
        #endif
    );
    skyLight = max(skyLight, vec3((nightVision * 0.5) * lmcoord.z));

    blockLight *= (
        saturate(lmcoord.x * lmcoord.x * 1.1)                                  // Blocklight
        #if LIGHTMAP_BLOCKLIGHT_AO != 100
        * (lmcoord.z * lightmap_blocklight_ao + (1. - lightmap_blocklight_ao)) // Blocklight AO
        #else
        * lmcoord.z
        #endif
        * saturate((luminance(skyLight) * 1.15 - 0.15 ) * -LIGHTMAP_BLOCKLIGHT_REDUCTION + 1) // Reduce Blocklight when it's bright
    );
    
    float caveLight = LIGHTMAP_MINIMUM_LIGHT * (lmcoord.y * (lmcoord.y - 2) + 1) * lmcoord.z;
    return blockLight + skyLight + caveLight;
}

#if CUSTOM_LIGHTMAP_MODE == 1
////////////////////////////////////////////////
// Normal Custom Lightmap
////////////////////////////////////////////////

vec3 getCustomLightmap(vec3 lmcoord /* lmcoord + AO */, float customLightmapBlend) {
    #ifndef LIGHTMAP_COMPLEX_BLOCKLIGHT
        const vec3 blocklightColor = lightmapBlock;
    #else
        #if LIGHTMAP_COMPLEX_BLOCKLIGHT_BLEND_CURVE != 50
            float blocklightColorBlend = pow(lmcoord.x, lightmap_complex_blocklight_blend_curve);
            vec3  blocklightColor = mix(lightmapComplexBlockDark, lightmapComplexBlockBright, blocklightColorBlend);
        #else
            vec3  blocklightColor = mix(lightmapComplexBlockDark, lightmapComplexBlockBright, lmcoord.x);
        #endif
        #if MC_VERSION >= 11900
            if (darknessFactor > 0) {

                blocklightColor *= sqsq(lmcoord.x);
                float timeOszillator  = sin(frameTimeCounter) * 0.5 + .5;
                float lightOszillator = sin(lmcoord.x * 15 + (frameTimeCounter * 2));
                float glitter         = saturate(lightOszillator * 500 - 495);

                vec3 darknessBlocklight = sqsq( saturate(lightOszillator) ) * mix( vec3(0.4,1.0,1.7), vec3(0.0, 0.8, 0.2),  timeOszillator);
                darknessBlocklight      = mix(darknessBlocklight, vec3(1), glitter);

                blocklightColor += darknessBlocklight * darknessFactor;
                lmcoord.x = saturate(lmcoord.x + lmcoord.x * glitter);

                lmcoord.x *= timeOszillator * 0.5 + 0.5;
                lmcoord.y *= timeOszillator;

            }
        #endif
    #endif

    #if LIGHTMAP_SKYLIGHT_CONTRAST != 50
    lmcoord.y = pow(lmcoord.y, lightmap_skylight_contrast);
    #endif
    #if LIGHTMAP_BLOCKLIGHT_CONTRAST != 50
    lmcoord.x = pow(lmcoord.x, lightmap_blocklight_contrast);
    #endif

    #ifdef NETHER
    vec3 skyLight = (lightmapNether / maxc(lightmapNether));
    lmcoord.y = LIGHTMAP_NETHER_SKY_BRIGHTNESS;
    #elif defined END
    vec3 skyLight = applySaturation(lightmapEnd / maxc(lightmapEnd), LIGHTMAP_END_SKY_SATURATION);
    lmcoord.y = LIGHTMAP_END_SKY_BRIGHTNESS;
    #else
    vec3 skyLight = mix(lightmapNight, lightmapDay, customLightmapBlend);
    #endif
    
    return mixLightmap(lmcoord, skyLight, blocklightColor);
}

vec3 getCustomLightmap(vec3 lmcoord /* lmcoord + AO */, float customLightmapBlend, vec3 blocklightExtraColor) {
    #ifndef LIGHTMAP_COMPLEX_BLOCKLIGHT
        vec3 blocklightColor = mix(lightmapBlock, blocklightExtraColor, maxc(blocklightExtraColor));
    #else
        #if LIGHTMAP_COMPLEX_BLOCKLIGHT_BLEND_CURVE != 50
            float blocklightColorBlend = pow(lmcoord.x, lightmap_complex_blocklight_blend_curve);
            vec3  blocklightColor = mix(lightmapComplexBlockDark, lightmapComplexBlockBright, blocklightColorBlend);
        #else
            vec3  blocklightColor = mix(lightmapComplexBlockDark, lightmapComplexBlockBright, lmcoord.x);
        #endif

        //blocklightExtraColor  = blocklightExtraColor * (luminance(lightmapBlock) / luminance(blocklightExtraColor));
        blocklightExtraColor  = saturate(blocklightExtraColor);
        blocklightColor = mix(lightmapBlock, blocklightExtraColor, maxc(blocklightExtraColor));

        #if MC_VERSION >= 11900
            if (darknessFactor > 0) {

                blocklightColor *= sqsq(lmcoord.x);
                float timeOszillator  = sin(frameTimeCounter) * 0.5 + .5;
                float lightOszillator = sin(lmcoord.x * 15 + (frameTimeCounter * 2));
                float glitter         = saturate(lightOszillator * 500 - 495);

                vec3 darknessBlocklight = sqsq( saturate(lightOszillator) ) * mix( vec3(0.4,1.0,1.7), vec3(0.0, 0.8, 0.2),  timeOszillator);
                darknessBlocklight      = mix(darknessBlocklight, vec3(1), glitter);

                blocklightColor += darknessBlocklight * darknessFactor;
                lmcoord.x = saturate(lmcoord.x + lmcoord.x * glitter);

                lmcoord.x *= timeOszillator * 0.5 + 0.5;
                lmcoord.y *= timeOszillator;

            }
        #endif
    #endif

    #if LIGHTMAP_SKYLIGHT_CONTRAST != 50
    lmcoord.y = pow(lmcoord.y, lightmap_skylight_contrast);
    #endif
    #if LIGHTMAP_BLOCKLIGHT_CONTRAST != 50
    lmcoord.x = pow(lmcoord.x, lightmap_blocklight_contrast);
    #endif

    #ifdef NETHER
    vec3 skyLight = (lightmapNether / maxc(lightmapNether));
    lmcoord.y = LIGHTMAP_NETHER_SKY_BRIGHTNESS;
    #elif defined END
    vec3 skyLight = applySaturation(lightmapEnd / maxc(lightmapEnd), LIGHTMAP_END_SKY_SATURATION);
    lmcoord.y = LIGHTMAP_END_SKY_BRIGHTNESS;
    #else
    vec3 skyLight = mix(lightmapNight, lightmapDay, customLightmapBlend);
    #endif
    
    return mixLightmap(lmcoord, skyLight, blocklightColor);
}

#else 

vec3 getCustomLightmap(vec2 lmcoord, float customLightmapBlend, float AO) {

    #ifdef NETHER

        vec3 skyLight = (lightmapNether / maxc(lightmapNether));
        lmcoord.y = LIGHTMAP_NETHER_SKY_BRIGHTNESS;

    #elif defined END

        vec3 skyLight = applySaturation(lightmapEnd / maxc(lightmapEnd), LIGHTMAP_END_SKY_SATURATION);
        lmcoord.y = LIGHTMAP_END_SKY_BRIGHTNESS;

    #else

        vec3 skyLight = mix(lightmapNight, lightmapDay, customLightmapBlend);

    #endif

    float caveLight = LIGHTMAP_MINIMUM_LIGHT * (lmcoord.y * (lmcoord.y - 2) + 1);

    return ( 
        lightmapBlock * lmcoord.x * (luminance(skyLight) * -lmcoord.y * 0.95 + 1) +
        skyLight * lmcoord.y * lmcoord.y +
        caveLight 
    ) * AO;
}

vec3 getCustomLightmap(vec2 lmcoord, float customLightmapBlend, float AO, vec3 blocklightExtraColor) {

    #ifdef NETHER

        vec3 skyLight = (lightmapNether / maxc(lightmapNether));
        lmcoord.y = LIGHTMAP_NETHER_SKY_BRIGHTNESS;

    #elif defined END

        vec3 skyLight = applySaturation(lightmapEnd / maxc(lightmapEnd), LIGHTMAP_END_SKY_SATURATION);
        lmcoord.y = LIGHTMAP_END_SKY_BRIGHTNESS;

    #else

        vec3 skyLight = mix(lightmapNight, lightmapDay, customLightmapBlend);

    #endif

    float blockLightBlend = maxc(blocklightExtraColor);
    blocklightExtraColor  = blocklightExtraColor * ( luminance(lightmapBlock) / luminance(blocklightExtraColor) );
    blocklightExtraColor  = saturate(blocklightExtraColor);
    vec3 blocklightColor  = mix(lightmapBlock, blocklightExtraColor, blockLightBlend);

    float caveLight = LIGHTMAP_MINIMUM_LIGHT * (lmcoord.y * (lmcoord.y - 2) + 1);

    return ( 
        blocklightColor * lmcoord.x * (luminance(skyLight) * -lmcoord.y * 0.95 + 1) +
        skyLight * lmcoord.y * lmcoord.y +
        caveLight 
    ) * AO;
}

#endif
