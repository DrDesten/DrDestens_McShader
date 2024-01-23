uniform sampler2D colortex2; // BlockID Buffer

float getID(vec2 coord) {
    return floor(texelFetch(colortex2, toIntCoords(coord), 0).r * 255 + 0.5);
}
float getID(ivec2 icoord) {
    return floor(texelFetch(colortex2, icoord, 0).r * 255 + 0.5);
}