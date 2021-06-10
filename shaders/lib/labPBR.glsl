//#define PBR

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
vec3 extractNormal(vec4 tex) {
    return vec3(tex.xy, sqrt(1.0 - dot(tex.xy, tex.xy))) * 2 - 1;
}
float extractAO(vec4 tex) {
    return tex.b;
}
float extractHeight(vec4 tex) {
    return tex.a;
}


// SPECULAR TEXTURE
float extractRoughness(vec4 tex) {
    return pow(1.0 - tex.r, 2.0);
}
float extractF0(vec4 tex) {
    return tex.g;
}