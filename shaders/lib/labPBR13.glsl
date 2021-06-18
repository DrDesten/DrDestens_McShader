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
vec3 extractNormal(vec4 n_tex, vec4 s_tex) {
    return vec3(n_tex.xy, sqrt(1.0 - dot(n_tex.xy, n_tex.xy))) * 2 - 1;
}
float extractAO(vec4 n_tex, vec4 s_tex) {
    return n_tex.b;
}
float extractHeight(vec4 n_tex, vec4 s_tex) {
    return n_tex.a;
}


// SPECULAR TEXTURE
float extractRoughness(vec4 n_tex, vec4 s_tex) {
    return pow(1.0 - s_tex.r, 2.0);
}
float extractF0(vec4 n_tex, vec4 s_tex) {
    return s_tex.g;
}

float extractEmission(vec4 n_tex, vec4 s_tex) {
    return s_tex.a * float(s_tex.a != 1);
}