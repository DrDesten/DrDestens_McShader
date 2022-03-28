float oldLighting(vec3 normal, vec3 viewUp) {
    return dot(normal, viewUp) * OLD_LIGHTING_STRENGTH + (1 - OLD_LIGHTING_STRENGTH);
}
float oldLighting(vec3 normal, mat4 gbufferModelView) {
    return oldLighting(normal, normalize(gbufferModelView[1].xyz));
}