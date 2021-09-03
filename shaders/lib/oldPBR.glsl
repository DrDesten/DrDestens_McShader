struct MaterialInfo {
    vec4  color;
    vec3  normal;

    float roughness;
    vec3  f0;
    float emission;
    float AO;
    float height;

    float subsurface;
    float porosity;
};

uniform sampler2D specular;
uniform sampler2D normals;

// TEXTURE READOUTS
vec4 NormalTex(vec2 coord) {
    return texture2D(normals, coord);
}
vec4 SpecularTex(vec2 coord) {
    return texture2D(specular, coord);
}


// NORMAL TEXTURE
vec3 extractNormal(vec4 nTex, vec4 sTex) {
    return nTex.xyz * 2 - 1;
}
float extractAO(vec4 nTex, vec4 sTex) {
    return 1.0;
}
float extractHeight(vec4 nTex, vec4 sTex) {
    return nTex.a;
}


// SPECULAR TEXTURE
float extractRoughness(vec4 nTex, vec4 sTex) {
    float tmp = 1. - sTex.r;
    return tmp*tmp;
}

float extractF0(vec4 nTex, vec4 sTex) {
    return sTex.g * 0.96 + 0.04;
}
vec3 extractF0(vec4 nTex, vec4 sTex, vec3 albedo) {
    return sTex.g * albedo * 0.96 + 0.04;
}
bool isMetal(vec4 nTex, vec4 sTex) {
    return true;
}

float extractSubsurf(vec4 nTex, vec4 sTex) {
    return 0.0;
}
float extractPorosity(vec4 nTex, vec4 sTex) {
    return 0.0;
}

float extractEmission(vec4 nTex, vec4 sTex) {
    return sTex.b;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////

MaterialInfo FullMaterial(vec2 coord, vec4 albedo) {
    vec4 NT = NormalTex(coord);
    vec4 ST = SpecularTex(coord);

    return MaterialInfo(
        albedo,
        extractNormal(NT, ST),

        extractRoughness(NT, ST),
        extractF0(NT, ST, albedo.rgb),
        extractEmission(NT, ST),
        extractAO(NT, ST),
        extractHeight(NT, ST),

        extractSubsurf(NT, ST),
        extractPorosity(NT, ST)
    );
}