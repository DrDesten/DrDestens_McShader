uniform sampler2D colortex4;

///////////////////////////////////////////////////////////
//              GAUSSIAN BLURS (NEW)
///////////////////////////////////////////////////////////





///////////////////////////////////////////////////////////
//              GAUSSIAN BLURS (OLD)
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
        col += texture(colortex4, pos).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_h10_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x - size * (i - 4.5), coord.y);
        col += texture(colortex4, pos).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_h16_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x - size * (i - 7.5), coord.y);
        col += texture(colortex4, pos).rgb * gaussian_16[i];
    }
    return col;
}

    // HORIZONTAL BLOOM CLAMP //////////////////////////////
vec3 gBlur_h6_bloom_c(vec2 coord, float size, float maxval) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x - size * (i - 2.5), coord.y);
        pos = clamp(pos, 0, maxval);
        col += texture(colortex4, pos).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_h10_bloom_c(vec2 coord, float size, float maxval) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x - size * (i - 4.5), coord.y);
        pos = clamp(pos, 0, maxval);
        col += texture(colortex4, pos).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_h16_bloom_c(vec2 coord, float size, float maxval) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x - size * (i - 7.5), coord.y);
        pos = clamp(pos, 0, maxval);
        col += texture(colortex4, pos).rgb * gaussian_16[i];
    }
    return col;
}

    // HORIZONTAL BLOOM LOD ///////////////////////////////

vec3 gBlur_h6_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x - size * (i - 2.5), coord.y);
        col += textureLod(colortex4, pos, lod).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_h10_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x - size * (i - 4.5), coord.y);
        col += textureLod(colortex4, pos, lod).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_h16_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x - size * (i - 7.5), coord.y);
        col += textureLod(colortex4, pos, lod).rgb * gaussian_16[i];
    }
    return col;
}


////////////////////////////////////////////////////////////////////////////////////////////////
    // VERTICAL BLOOM /////////////////////////////////////

vec3 gBlur_v6_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 2.5));
        col += texture(colortex4, pos).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_v10_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 4.5));
        col += texture(colortex4, pos).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_v16_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 7.5));
        col += texture(colortex4, pos).rgb * gaussian_16[i];
    }
    return col;
}

    // VERTICAL BLOOM CLAMP ///////////////////////////////
vec3 gBlur_v6_bloom_c(vec2 coord, float size, float maxval) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 2.5));
        pos = clamp(pos, 0, maxval);
        col += texture(colortex4, pos).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_v10_bloom_c(vec2 coord, float size, float maxval) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 4.5));
        pos = clamp(pos, 0, maxval);
        col += texture(colortex4, pos).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_v16_bloom_c(vec2 coord, float size, float maxval) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 7.5));
        pos = clamp(pos, 0, maxval);
        col += texture(colortex4, pos).rgb * gaussian_16[i];
    }
    return col;
}

    // VERTICAL BLOOM LOD /////////////////////////////////

vec3 gBlur_v6_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 6; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 2.5));
        col += textureLod(colortex4, pos, lod).rgb * gaussian_6[i];
    }
    return col;
}
vec3 gBlur_v10_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 10; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 4.5));
        col += textureLod(colortex4, pos, lod).rgb * gaussian_10[i];
    }
    return col;
}
vec3 gBlur_v16_bloom(vec2 coord, float size, float lod) {
    vec3 col = vec3(0);
    for (int i = 0; i < 16; i++) {
        vec2 pos = vec2(coord.x, coord.y - size * (i - 7.5));
        col += textureLod(colortex4, pos, lod).rgb * gaussian_16[i];
    }
    return col;
}