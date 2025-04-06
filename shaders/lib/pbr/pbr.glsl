#if !defined PBR_PBR_GLSL
#define PBR_PBR_GLSL

#include "structs.glsl"
#include "/core/core.glsl"

// Lab PBR
#if PBR_FORMAT == 1

vec3 readNormal(vec4 normalTexture, vec4 specularTexture) {
    vec2 n = normalTexture.xy * 2 - 1;
    return vec3(n, sqrt(1.0 - sqmag(n)));
}
float readAO(vec4 normalTexture, vec4 specularTexture) {
    return normalTexture.b;
}
float readHeight(vec4 normalTexture, vec4 specularTexture) {
    return normalTexture.a;
}
float readRoughness(vec4 normalTexture, vec4 specularTexture) {
    return sq(1. - specularTexture.r);
}
float readReflectance(vec4 normalTexture, vec4 specularTexture) {
    return specularTexture.g;
}
bool isMetal(vec4 normalTexture, vec4 specularTexture) {
    return specularTexture.g > 0.9;
}
float readSubsurface(vec4 normalTexture, vec4 specularTexture) {
    return specularTexture.z > 0.25294117647 && !isMetal(normalTexture, specularTexture) ? specularTexture.z : 0.0;
}
float readPorosity(vec4 normalTexture, vec4 specularTexture) {
    return specularTexture.z < 0.25294117647 && !isMetal(normalTexture, specularTexture) ? specularTexture.z : 0.0;
}
float readEmission(vec4 normalTexture, vec4 specularTexture) {
    return specularTexture.a * float(specularTexture.a != 1);
}

// Old PBR
#else 

// NORMAL TEXTURE
vec3 readNormal(vec4 nTex, vec4 sTex) {
    return normalize(nTex.xyz * 2 - 1);
}
float readAO(vec4 nTex, vec4 sTex) {
    return 1.0;
}
float readHeight(vec4 nTex, vec4 sTex) {
    return nTex.a;
}

// SPECULAR TEXTURE
float readRoughness(vec4 nTex, vec4 sTex) {
    float tmp = 1. - sTex.r;
    return tmp*tmp;
}
float readReflectance(vec4 nTex, vec4 sTex) {
    return sTex.g * 0.96 + 0.04;
}
float readSubsurface(vec4 nTex, vec4 sTex) {
    return 0.0;
}
float readPorosity(vec4 nTex, vec4 sTex) {
    return 0.0;
}
float readEmission(vec4 nTex, vec4 sTex) {
    return sTex.b;
}

#endif

// Reading, Encoding and Decoding
RawMaterial readMaterial(vec4 n, vec4 s) {
    RawMaterial material;

    material.normal = readNormal(n, s);
    material.height = readHeight(n, s);
    material.ao     = readAO(n, s);

    material.roughness   = readRoughness(n, s);
    material.reflectance = readReflectance(n, s);
    material.subsurface  = readSubsurface(n, s);
    material.porosity    = readPorosity(n, s);
    material.emission    = readEmission(n, s); 

    return material;
}

vec4 encodeMaterial(MaterialTexture material) {
    vec2 encoded = vec4to16x2(vec4(material.roughness, material.reflectance, material.height, material.emission));
    return vec4(encoded, 0, 1);
}

// Material

// Lab PBR
#if PBR_FORMAT == 1

/* const vec3 metalsF0[8] = vec3[8](
    vec3(0.7323620366092286, 0.7167327174985388, 0.7091896461414436), // Iron
    vec3(1.0539195094529696, 1.027785864151901,  0.6520659895749682), // Gold
    vec3(0.9706793033860285, 0.9777863969150392, 0.9917750974816536), // Aluminium
    vec3(0.7487388173705779, 0.7470894380842715, 0.7605161153716048), // Chrome
    vec3(1.0349547086698894, 0.9518412528274076, 0.7662936415871581), // Copper
    vec3(0.82339703574297,   0.821581064334115,  0.8457226032417902), // Lead
    vec3(0.8426306452778194, 0.8253700126733226, 0.7968226770078278), // Platinum
    vec3(1.0440489482492765, 1.0696036644002451, 1.1282074921867093)  // Silver
); */
const vec3 metalsF0[8] = vec3[8](
    vec3(0.7323620366092286, 0.7167327174985388, 0.7091896461414436), // Iron
    vec3(1.0,                1.0,                0.6520659895749682), // Gold
    vec3(0.9706793033860285, 0.9777863969150392, 0.9917750974816536), // Aluminium
    vec3(0.7487388173705779, 0.7470894380842715, 0.7605161153716048), // Chrome
    vec3(1.0,                0.9518412528274076, 0.7662936415871581), // Copper
    vec3(0.82339703574297,   0.821581064334115,  0.8457226032417902), // Lead
    vec3(0.8426306452778194, 0.8253700126733226, 0.7968226770078278), // Platinum
    vec3(1.0,                1.0               , 1.0               )  // Silver
);

vec3 decodeReflectance(float reflectance, vec3 albedo) {
#ifdef HARDCODED_METALS
    return reflectance < 229.5/255 
        ? vec3(reflectance) 
        : ( reflectance < 237.5/255 
            ? metalsF0[int((reflectance * 255) + 0.5) - 230] 
            : albedo 
        );
#else
    return reflectance < 229.5/255 
        ? vec3(reflectance) 
        : albedo;
#endif
}
vec3 decodeReflectanceTint(float reflectance, vec3 albedo) {
#ifdef HARDCODED_METALS
    return reflectance < 229.5/255 
        ? vec3(1) 
        : ( reflectance < 237.5/255 
            ? metalsF0[int((reflectance * 255) + 0.5) - 230] 
            : albedo 
        );
#else
    return reflectance < 229.5/255 
        ? vec3(1) 
        : albedo;
#endif
}


// Old PBR
#else 

vec3 decodeReflectance(float reflectance, vec3 albedo) {
    return reflectance * albedo;
}
vec3 decodeReflectanceTint(float reflectance, vec3 albedo) {
    return vec3(1);
}

#endif

Material getMaterial(MaterialTexture tex, vec3 lightmap, vec3 albedo) {
    return Material(
        gamma(albedo),
        tex.roughness,
        decodeReflectance(tex.reflectance, albedo),
        tex.emission,
        tex.height,
        lightmap.z,
        lightmap.xy,
        0,
        0
    );
}

Material getMaterial(RawMaterial mat, vec3 lightmap, vec3 albedo) {
    return Material(
        gamma(albedo),
        mat.roughness,
        decodeReflectance(mat.reflectance, albedo),
        mat.emission,
        mat.height,
        lightmap.z,
        lightmap.xy,
        mat.subsurface,
        mat.porosity
    );
}

#endif