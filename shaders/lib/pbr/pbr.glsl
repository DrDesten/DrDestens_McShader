#if !defined PBR_PBR_GLSL
#define PBR_PBR_GLSL

struct RawMaterial {
    vec3  normal;
    float roughness;
    float reflectance;
    float emission;
    float height;
    float ao;
};
struct MaterialTexture {
    float roughness;
    float reflectance;
    float emission;
    float height;
    float ao;
    vec2  lightmap;
};
struct Material {
    vec3  albedo;
    float roughness;
    vec3  f0;
    float emission;
    float height;
    float ao;
    vec2  lightmap;
    float subsurface;
    float porosity;
};

// NORMAL TEXTURE
vec3 readNormal(vec4 nTex) {
    vec2 n = nTex.xy * 2 - 1;
    return vec3(n, sqrt(1.0 - sqmag(n)));
}
float readAO(vec4 nTex) {
    return nTex.b;
}
float readHeight(vec4 nTex) {
    return nTex.a;
}

// SPECULAR TEXTURE
float readRoughness(vec4 sTex) {
    return sq(1. - sTex.r);
}
float readReflectance(vec4 sTex) {
    return sTex.g;
}
float readEmission(vec4 sTex) {
    return sTex.a * float(sTex.a != 1);
}

// Reading, Encoding and Decoding
RawMaterial readMaterial(vec4 normaltex, vec4 speculartex) {
    RawMaterial material;

    material.normal = readNormal(normaltex);
    material.height = readHeight(normaltex);
    material.ao     = readAO(normaltex);

    material.roughness   = readRoughness(speculartex);
    material.reflectance = readReflectance(speculartex);
    material.emission    = readEmission(speculartex);

    return material;
}

int getCoordinateId(ivec2 fragCoord) {
    return (fragCoord.x % 2) + 2 * (fragCoord.y % 2);
}
int getCoordinateId(vec2 fragCoord) {
    return getCoordinateId(ivec2(fragCoord));
}

vec4 encodeMaterial(MaterialTexture material, ivec2 fragCoord) {
    vec4 encoded;

    encoded.x = material.lightmap.x;
    encoded.y = material.lightmap.y;
    encoded.z = material.ao;
    
    int id = getCoordinateId(fragCoord);
    if (id == 0) encoded.w = material.roughness;
    if (id == 1) encoded.w = material.reflectance;
    if (id == 2) encoded.w = material.height;
    if (id == 3) encoded.w = material.emission;

    return encoded;
}

MaterialTexture decodeMaterial(vec4 samples[4], int ids[4]) {
    MaterialTexture material;

    material.lightmap.x = samples[0].x;
    material.lightmap.y = samples[0].y;
    material.ao   = samples[0].z;

    for (int i = 0; i < 4; i++) {
        if (ids[i] == 0) material.roughness   = samples[i].w;
        if (ids[i] == 1) material.reflectance = samples[i].w;
        if (ids[i] == 2) material.height      = samples[i].w;
        if (ids[i] == 3) material.emission    = samples[i].w;
    }

    return material;
}

// Material

Material getMaterial(MaterialTexture tex, vec3 albedo) {
    return Material(
        albedo,
        tex.roughness,
        vec3(tex.reflectance),
        tex.emission,
        tex.height,
        tex.ao,
        tex.lightmap,
        0,
        0
    );
}

#endif