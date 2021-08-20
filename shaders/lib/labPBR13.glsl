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
    float tmp = 1. - sTex.r;
    return tmp*tmp;
}

float extractF0(vec4 nTex, vec4 sTex) {
    return sTex.g;
}
vec3 extractF0(vec4 nTex, vec4 sTex, vec3 albedo) {
    #ifdef HARDCODED_METALS
    return sTex.g < 229.5/255 ? sTex.ggg : (sTex.g < 237.5/255 ? metalsF0[int((sTex.g * 255) + 0.5) - 230] : albedo);
    #else
    return sTex.g < 229.5/255 ? sTex.ggg : albedo;
    #endif
    /* if (sTex.g < 229.5/255) {
        return sTex.ggg;
    } else if (sTex.g < 237.5/255) {
        int index = int((sTex.g * 255) + 0.5) - 230;
        return metalsF0[index];
    } else {
        return albedo;
    } */
}
bool isMetal(vec4 nTex, vec4 sTex) {
    return sTex.g > 0.9;
}

float extractSubsurf(vec4 nTex, vec4 sTex) {
    return sTex.z > 0.25294117647 && !isMetal(nTex, sTex) ? sTex.z : 0.0;
}
float extractPorosity(vec4 nTex, vec4 sTex) {
    return sTex.z < 0.25294117647 && !isMetal(nTex, sTex) ? sTex.z : 0.0;
}

float extractEmission(vec4 nTex, vec4 sTex) {
    return sTex.a * float(sTex.a != 1);
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