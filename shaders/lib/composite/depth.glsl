uniform sampler2D depthtex0; // Depth Buffer

float getDepth(in vec2 coord) {
    return texture(depthtex0, coord).x;
}
float getDepth(in ivec2 icoord) {
    return texelFetch(depthtex0, icoord, 0).x;
}