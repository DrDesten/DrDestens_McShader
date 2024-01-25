uniform float lightBrightness;

vec3 getAmbientLight(vec2 lightmap, float ao) {
    return vec3((lightmap.x + lightmap.y * lightBrightness) * ao / 2);
}