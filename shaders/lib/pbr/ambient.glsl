#if !defined PBR_AMBIENT_GLSL
#define PBR_AMBIENT_GLSL

#include "include.glsl"

vec3 getAmbientLight(vec2 lightmap, float ao) {
    return vec3((lightmap.x + lightmap.y * lightBrightness) * ao / 2);
}

#endif