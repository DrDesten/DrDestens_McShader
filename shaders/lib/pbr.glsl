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

// NORMAL TEXTURE
vec3 readNormal(vec4 nTex) {
    vec2 n = nTex.xy * 2 - 1;
    return vec3(n, sqrt(1.0 - dot(n, n)));
}
float readAO(vec4 nTex) {
    return nTex.b;
}
float readHeight(vec4 nTex) {
    return nTex.a;
}

// SPECULAR TEXTURE
float readRoughness(vec4 sTex) {
    float tmp = 1. - sTex.r;
    return tmp*tmp;
}
float readReflectance(vec4 sTex) {
    return sTex.g;
}
float readEmission(vec4 sTex) {
    return sTex.a * float(sTex.a != 1);
}

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

    encoded.x = material.roughness;
    encoded.y = material.reflectance;
    encoded.z = material.emission;
    
    int id = getCoordinateId(fragCoord);
    if (id == 0) encoded.w = material.height;
    if (id == 1) encoded.w = material.ao;
    if (id == 2) encoded.w = material.lightmap.x;
    if (id == 3) encoded.w = material.lightmap.y;

    return encoded;
}

MaterialTexture decodeMaterial(vec4 samples[4], int ids[4]) {
    MaterialTexture material;

    material.roughness   = samples[0].x;
    material.reflectance = samples[0].y;
    material.emission    = samples[0].z;

    for (int i = 0; i < 4; i++) {
        if (ids[i] == 0) material.height     = samples[i].w;
        if (ids[i] == 1) material.ao         = samples[i].w;
        if (ids[i] == 2) material.lightmap.x = samples[i].w;
        if (ids[i] == 3) material.lightmap.y = samples[i].w;
    }

    return material;
}