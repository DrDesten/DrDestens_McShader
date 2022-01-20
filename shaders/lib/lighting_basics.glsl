uniform float nightVision;
uniform float customLightmapBlend;

vec3 getLightmap(vec2 lmcoord, float AO) {
    const vec3 dayColor   = vec3(LIGHTMAP_SKY_DAY_R, LIGHTMAP_SKY_DAY_G, LIGHTMAP_SKY_DAY_B);
    const vec3 nightColor = vec3(LIGHTMAP_SKY_NIGHT_R, LIGHTMAP_SKY_NIGHT_G, LIGHTMAP_SKY_NIGHT_B);
    
    #if LIGHTMAP_COMPLEX_BLOCKLIGHT_BLEND_CURVE != 50
        float blocklightColorBlend = pow(lmcoord.x, lightmap_complex_blocklight_blend_curve);
        vec3  blocklightColor = mix(vec3(LIGHTMAP_COMPLEX_BLOCK_DARK_R, LIGHTMAP_COMPLEX_BLOCK_DARK_G, LIGHTMAP_COMPLEX_BLOCK_DARK_B), vec3(LIGHTMAP_COMPLEX_BLOCK_BRIGHT_R, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_G, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_B), blocklightColorBlend);
    #else
        vec3  blocklightColor = mix(vec3(LIGHTMAP_COMPLEX_BLOCK_DARK_R, LIGHTMAP_COMPLEX_BLOCK_DARK_G, LIGHTMAP_COMPLEX_BLOCK_DARK_B), vec3(LIGHTMAP_COMPLEX_BLOCK_BRIGHT_R, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_G, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_B), lmcoord.x);
    #endif

    #if LIGHTMAP_SKYLIGHT_CONTRAST != 50
    lmcoord.y = pow(lmcoord.y, lightmap_skylight_contrast);
    #endif
    #if LIGHTMAP_BLOCKLIGHT_CONTRAST != 50
    lmcoord.x = pow(lmcoord.x, lightmap_blocklight_contrast);
    #endif

    vec3 skyLight   = mix(nightColor, dayColor, customLightmapBlend) * (
        lmcoord.y * LIGHTMAP_SKYLIGHT_BRIGHTNESS                        // Skylight
        #if LIGHTMAP_SKYLIGHT_AO != 100
        * (AO * lightmap_skylight_ao + (1. - lightmap_skylight_ao))     // Skylight AO
        #else
        * AO
        #endif
    );
    skyLight = max(skyLight, vec3((nightVision * 0.5 + LIGHTMAP_MINIMUM_LIGHT) * AO));

    vec3 blockLight = blocklightColor * (
        (lmcoord.x * lmcoord.x * LIGHTMAP_BLOCKLIGHT_BRIGHTNESS)         // Blocklight
        #if LIGHTMAP_BLOCKLIGHT_AO != 100
        * (AO * lightmap_blocklight_ao + (1. - lightmap_blocklight_ao))  // Blocklight AO
        #else
        * AO
        #endif
    );

    return blockLight + skyLight;
}

void getLmDir(in vec2 lco, out vec2 skyLight, out vec2 blockLight) {
    blockLight = vec2(dFdx(lco.x), dFdy(lco.x));
    blockLight = abs(blockLight.x) + abs(blockLight.y) < 1e-6 ? vec2(0) : normalize(blockLight);
    skyLight   = vec2(dFdx(lco.y), dFdy(lco.y));
    skyLight   = abs(skyLight.x)   + abs(skyLight.y)   < 1e-6 ? vec2(0) : normalize(skyLight);
}

vec2 getBlocklightDir(vec2 lco, mat2 tbn) {
    vec2 blockLightDir = vec2(dFdx(lco.x), dFdy(lco.x));
    return abs(blockLightDir.x) + abs(blockLightDir.y) < 1e-6 ? vec2(0,1) : normalize(tbn * blockLightDir); // By doing matrix * vector, I am using the transpose of the matrix. Since tbn is purely rotational, this inverts the matrix.
}