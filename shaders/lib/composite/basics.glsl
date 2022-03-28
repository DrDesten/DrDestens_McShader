uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

ivec2 toIntCoords(vec2 coord) {
    return ivec2(coord * screenSize);
}
ivec2 toIntCoords(vec2 coord, vec2 samplerSize) {
    return ivec2(coord * samplerSize);
}