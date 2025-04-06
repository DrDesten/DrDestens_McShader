uniform sampler2D texture;  // Color

vec4 getAlbedo(vec2 coord) {
    return texture(texture, coord);
}