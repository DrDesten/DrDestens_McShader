
float generateHeight(vec3 color) {
    return (color.r + color.g + color.g) * 0.33333333;
}
vec3 generateNormals(vec3 heights, float pixelSize) {
    // heights.x = center
    // heights.y = right
    // heights.z = bottom
    vec3 n = vec3(heights.y - heights.x, heights.z - heights.x, pixelSize);
    return normalize(n);
}
float generateRoughness(vec3 color) {
    return 1 - dot(color, color);
}