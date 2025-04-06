uniform sampler2D lightmap; // lightmap

vec3 getLightmap(vec2 coord) {
    return texture(lightmap, coord).rgb;
}
