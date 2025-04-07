uniform sampler2D gcolor;  // Color

vec4 getAlbedo(vec2 coord) {
    return texture(gcolor, coord);
}