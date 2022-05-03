float oldLighting(vec3 normal, vec3 viewUp) {
    return dot(normal, viewUp) * OLD_LIGHTING_STRENGTH + (1 - OLD_LIGHTING_STRENGTH);
}
float oldLighting(vec3 normal, mat4 gbufferModelView) {
    const vec3 oldLightVec = normalize(vec3(1,4,2));
    return dot(normal, mat3(gbufferModelView) * oldLightVec) * OLD_LIGHTING_STRENGTH + (1 - OLD_LIGHTING_STRENGTH);
}