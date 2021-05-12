
uniform sampler2D colortex5;

///////////////////////////////////////////////////////////
//              GAUSSIAN BLURS
///////////////////////////////////////////////////////////

// Horizontal

vec3 gBlur_horizontal5_color(vec2 coord, float size) {
    vec3 col = vec3(0);
    col += getAlbedo_int(vec2(coord.x - size - size, coord.y)) * 0.06136;
    col += getAlbedo_int(vec2(coord.x - size, coord.y)) * 0.24477;
    col += getAlbedo_int(vec2(coord.x, coord.y)) * 0.38774;
    col += getAlbedo_int(vec2(coord.x + size, coord.y)) * 0.24477;
    col += getAlbedo_int(vec2(coord.x + size + size, coord.y)) * 0.06136;
    return col;
}
vec3 gBlur_horizontal7_color(vec2 coord, float size) {
    vec3 col = vec3(0);
    col += getAlbedo_int(vec2(coord.x - (size * 3), coord.y)) * 0.00598;
    col += getAlbedo_int(vec2(coord.x - size - size, coord.y)) * 0.060626;
    col += getAlbedo_int(vec2(coord.x - size, coord.y)) * 0.241843;
    col += getAlbedo_int(vec2(coord.x, coord.y)) * 0.383103;
    col += getAlbedo_int(vec2(coord.x + size, coord.y)) * 0.241843;
    col += getAlbedo_int(vec2(coord.x + size + size, coord.y)) * 0.060626;
    col += getAlbedo_int(vec2(coord.x + (size * 3), coord.y)) * 0.00598;
    return col;
}


vec3 gBlur_horizontal5_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    col += texture(colortex5, vec2(coord.x - size - size, coord.y)).rgb * 0.06136;
    col += texture(colortex5, vec2(coord.x - size, coord.y)).rgb * 0.24477;
    col += texture(colortex5, vec2(coord.x, coord.y)).rgb * 0.38774;
    col += texture(colortex5, vec2(coord.x + size, coord.y)).rgb * 0.24477;
    col += texture(colortex5, vec2(coord.x + size + size, coord.y)).rgb * 0.06136;
    return col;
}
vec3 gBlur_horizontal7_bloom(vec2 coord, float size) {
    vec3 col = vec3(0);
    col += texture(colortex5, vec2(coord.x - (size * 3), coord.y)).rgb * 0.00598;
    col += texture(colortex5, vec2(coord.x - size - size, coord.y)).rgb * 0.060626;
    col += texture(colortex5, vec2(coord.x - size, coord.y)).rgb * 0.241843;
    col += texture(colortex5, vec2(coord.x, coord.y)).rgb * 0.383103;
    col += texture(colortex5, vec2(coord.x + size, coord.y)).rgb * 0.241843;
    col += texture(colortex5, vec2(coord.x + size + size, coord.y)).rgb * 0.060626;
    col += texture(colortex5, vec2(coord.x + (size * 3), coord.y)).rgb * 0.00598;
    return col;
}
vec3 gBlur_horizontal7_bloom_clamp(vec2 coord, float size, float maximum) {
    vec3 col = vec3(0);
    col += texture(colortex5, clamp(vec2(coord.x - (size * 3), coord.y), 0, maximum)).rgb * 0.00598;
    col += texture(colortex5, clamp(vec2(coord.x - size - size, coord.y), 0, maximum)).rgb * 0.060626;
    col += texture(colortex5, clamp(vec2(coord.x - size, coord.y), 0, maximum)).rgb * 0.241843;
    col += texture(colortex5, clamp(vec2(coord.x, coord.y), 0, maximum)).rgb * 0.383103;
    col += texture(colortex5, clamp(vec2(coord.x + size, coord.y), 0, maximum)).rgb * 0.241843;
    col += texture(colortex5, clamp(vec2(coord.x + size + size, coord.y), 0, maximum)).rgb * 0.060626;
    col += texture(colortex5, clamp(vec2(coord.x + (size * 3), coord.y), 0, maximum)).rgb * 0.00598;
    return col;
}


// Vertical

vec3 gBlur_vertical5_bloom(vec2 coord, float size) {
    vec3 color;
    color += texture(colortex5, vec2(coord.x, coord.y - size - size)).rgb * 0.06136;
    color += texture(colortex5, vec2(coord.x, coord.y - size)).rgb * 0.24477;
    color += texture(colortex5, vec2(coord.x, coord.y)).rgb * 0.38774;
    color += texture(colortex5, vec2(coord.x, coord.y + size)).rgb * 0.24477;
    color += texture(colortex5, vec2(coord.x, coord.y + size + size)).rgb * 0.06136;
    return color;
}
vec3 gBlur_vertical7_bloom(vec2 coord, float size) {
    vec3 color;
    color += texture(colortex5, vec2(coord.x, coord.y - (size * 3))).rgb * 0.00598;
    color += texture(colortex5, vec2(coord.x, coord.y - size - size)).rgb * 0.060626;
    color += texture(colortex5, vec2(coord.x, coord.y - size)).rgb * 0.241843;
    color += texture(colortex5, vec2(coord.x, coord.y)).rgb * 0.383103;
    color += texture(colortex5, vec2(coord.x, coord.y + size)).rgb * 0.241843;
    color += texture(colortex5, vec2(coord.x, coord.y + size + size)).rgb * 0.060626;
    color += texture(colortex5, vec2(coord.x, coord.y + (size * 3))).rgb * 0.00598;
    return color;
}
vec3 gBlur_vertical7_bloom_clamp(vec2 coord, float size, float maximum) {
    vec3 color;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y - (size * 3)), 0, maximum)).rgb * 0.00598;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y - size - size), 0, maximum)).rgb * 0.060626;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y - size), 0, maximum)).rgb * 0.241843;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y), 0, maximum)).rgb * 0.383103;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y + size), 0, maximum)).rgb * 0.241843;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y + size + size), 0, maximum)).rgb * 0.060626;
    color += texture(colortex5, clamp(vec2(coord.x, coord.y + (size * 3)), 0, maximum)).rgb * 0.00598;
    return color;
}
