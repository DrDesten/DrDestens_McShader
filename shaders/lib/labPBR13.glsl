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
    vec2 n = nTex.xy * 2 - 1;
    return vec3(n, sqrt(1.0 - dot(n, n)));
}
float extractAO(vec4 nTex, vec4 sTex) {
    return nTex.b;
}
float extractHeight(vec4 nTex, vec4 sTex) {
    return nTex.a;
}


// SPECULAR TEXTURE
float extractRoughness(vec4 nTex, vec4 sTex) {
    return pow(1.0 - sTex.r, 2.0);
}
float extractF0(vec4 nTex, vec4 sTex) {
    return sTex.g;
}

float extractEmission(vec4 nTex, vec4 sTex) {
    return sTex.a * float(sTex.a != 1);
}