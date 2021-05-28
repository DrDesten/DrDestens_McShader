
//#define BLOOM
#define BLOOM_AMOUNT 0.10              // [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]

uniform sampler2D colortex5;



///////////////////////////////////////////////////////////
//              GAUSSIAN BLURS
///////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////
    // HORIZONTAL COLOR ///////////////////////////////////

vec3 gBlur_h6_col(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x - size * (i - 2.5), coord.y);
        col += texture(colortex0, pos).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_h10_col(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x - size * (i - 4.5), coord.y);
        col += texture(colortex0, pos).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_h16_col(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x - size * (i - 7.5), coord.y);
        col += texture(colortex0, pos).rgb * gaussian_16[i];
    }
    return col;
}

    // HORIZONTAL COLOR LOD ///////////////////////////////

vec3 gBlur_h6_col(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x - size * (i - 2.5), coord.y);
        col += textureLod(colortex0, pos, lod).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_h10_col(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x - size * (i - 4.5), coord.y);
        col += textureLod(colortex0, pos, lod).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_h16_col(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x - size * (i - 7.5), coord.y);
        col += textureLod(colortex0, pos, lod).rgb * gaussian_16[i];
    }
    return col;
}


////////////////////////////////////////////////////////////////////////////////////////////////
    // HORIZONTAL BLOOM ///////////////////////////////////

vec3 gBlur_h6_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x - size * (i - 2.5), coord.y);
        col += texture(colortex5, pos).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_h10_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x - size * (i - 4.5), coord.y);
        col += texture(colortex5, pos).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_h16_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x - size * (i - 7.5), coord.y);
        col += texture(colortex5, pos).rgb * gaussian_16[i];
    }
    return col;
}

    // HORIZONTAL BLOOM LOD ///////////////////////////////

vec3 gBlur_h6_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x - size * (i - 2.5), coord.y);
        col += textureLod(colortex5, pos, lod).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_h10_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x - size * (i - 4.5), coord.y);
        col += textureLod(colortex5, pos, lod).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_h16_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x - size * (i - 7.5), coord.y);
        col += textureLod(colortex5, pos, lod).rgb * gaussian_16[i];
    }
    return col;
}


////////////////////////////////////////////////////////////////////////////////////////////////
    // VERTICAL BLOOM /////////////////////////////////////

vec3 gBlur_v6_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 2.5));
        col += texture(colortex5, pos).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_v10_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 4.5));
        col += texture(colortex5, pos).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_v16_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 7.5));
        col += texture(colortex5, pos).rgb * gaussian_16[i];
    }
    return col;
}

    // VERTICAL BLOOM LOD /////////////////////////////////

vec3 gBlur_v6_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 2.5));
        col += textureLod(colortex5, pos, lod).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_v10_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 4.5));
        col += textureLod(colortex5, pos, lod).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_v16_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 7.5));
        col += textureLod(colortex5, pos, lod).rgb * gaussian_16[i];
    }
    return col;
}