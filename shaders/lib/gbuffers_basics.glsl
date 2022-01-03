uniform sampler2D texture;  // Color
uniform sampler2D lightmap; // lightmap

#define FD0 gl_FragData[0]
#define FD1 gl_FragData[1]
#define FD2 gl_FragData[2]
#define FD3 gl_FragData[3]

vec4 getAlbedo(vec2 coord) {
    return texture2D(texture, coord);
}

vec3 getLightmap(vec2 coord) {
    return texture2D(lightmap, coord).rgb;
}

void getLmDir(in vec2 lco, out vec2 skyLight, out vec2 blockLight) {
    blockLight = vec2(dFdx(lco.x), dFdy(lco.x));
    blockLight = abs(blockLight.x) + abs(blockLight.y) < 1e-6 ? vec2(0) : normalize(blockLight);
    skyLight   = vec2(dFdx(lco.y), dFdy(lco.y));
    skyLight   = abs(skyLight.x)   + abs(skyLight.y)   < 1e-6 ? vec2(0) : normalize(skyLight);
}

vec2 getBlocklightDir(vec2 lco, mat2 tbn) {
    vec2 blockLightDir = vec2(dFdx(lco.x), dFdy(lco.x));
    return abs(blockLightDir.x) + abs(blockLightDir.y) < 1e-6 ? vec2(0,1) : normalize(tbn * blockLightDir); // By doing matrix * vector, I am using the transpose of the matrix. Since tbn is purely rotational, this inverts the matrix.
}

float codeID(float blockId) {
    return blockId * .00392156862745; // 0.00392156862745 == 1/255
}