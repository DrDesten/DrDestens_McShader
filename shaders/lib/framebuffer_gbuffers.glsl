uniform sampler2D texture;  // Color
uniform sampler2D lightmap; // lightmap

#define FD0 gl_FragData[0]
#define FD1 gl_FragData[1]
#define FD2 gl_FragData[2]
#define FD3 gl_FragData[3]

vec4 getAlbedo(vec2 coord) {
    return texture(texture, coord);
}

vec3 getLightmap(vec2 coord) {
    return texture(lightmap, coord).rgb;
}