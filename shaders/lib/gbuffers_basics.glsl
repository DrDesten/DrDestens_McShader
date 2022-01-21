uniform sampler2D texture;  // Color

vec4 getAlbedo(vec2 coord) {
    return texture2D(texture, coord);
}

void getLmDir(in vec2 lco, out vec2 skyLight, out vec2 blockLight) {
    blockLight = vec2(dFdx(lco.x), dFdy(lco.x));
    blockLight = abs(blockLight.x) + abs(blockLight.y) < 1e-6 ? vec2(0) : normalize(blockLight);
    skyLight   = vec2(dFdx(lco.y), dFdy(lco.y));
    skyLight   = abs(skyLight.x)   + abs(skyLight.y)   < 1e-6 ? vec2(0) : normalize(skyLight);
}
void getLmDir(in vec2 lco, out vec2 skyLight, out vec2 blockLight, mat2 tbn) {
    blockLight = vec2(dFdx(lco.x), dFdy(lco.x));
    blockLight = abs(blockLight.x) + abs(blockLight.y) < 1e-6 ? vec2(0,.75) : normalize(tbn * blockLight);
    skyLight   = vec2(dFdx(lco.y), dFdy(lco.y));
    skyLight   = abs(skyLight.x)   + abs(skyLight.y)   < 1e-6 ? vec2(.75,0) : normalize(tbn * skyLight);
}

vec2 getBlocklightDir(vec2 lco, mat2 tbn) {
    vec2 blockLightDir = vec2(dFdx(lco.x), dFdy(lco.x));
    return abs(blockLightDir.x) + abs(blockLightDir.y) < 1e-6 ? vec2(0,.75) : normalize(tbn * blockLightDir); // By doing matrix * vector, I am using the transpose of the matrix. Since tbn is purely rotational, this inverts the matrix.
}

float codeID(float blockId) {
    return blockId * .00392156862745; // 0.00392156862745 == 1/255
}

void alphaTest(float alpha, float threshhold) {
    if (alpha < threshhold) discard;
}
