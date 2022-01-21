#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/lighting_basics.glsl"

uniform float daynight;
uniform float sunset;
uniform float rainStrength;
uniform vec3  fogColor;

#include "/lib/fog_sky.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float nearInverse;
uniform float far;
uniform sampler2D colortex7;
const bool colortex7MipmapEnabled = true;

float filteredAO(vec3 screenPos) {
    float ao = 0;
    float wt = 0;
    float ld = linearizeDepthf(screenPos.z, nearInverse);
    for (int i = 0; i < 4; i++) {
        vec2  offs = starOffsets[i] * screenSizeInverse * 2;
        float s    = textureLod(colortex7, screenPos.xy * 0.75 + offs, 1).x;
        float sd   = getDepth(offs * (3/2) + screenPos.xy);

        float w    = max(abs(ld - linearizeDepthf(sd, nearInverse)) * -2.0 + 1, 0.00001);
        wt        += w;
        ao         = s * w + ao;
    }
    ao /= wt;
    return ao;
}

/* DRAWBUFFERS:0 */
void main() {
    vec3  color = getAlbedo(ivec2(gl_FragCoord.xy));
    float depth = getDepth(ivec2(gl_FragCoord.xy));
    float id    = getID(ivec2(gl_FragCoord.xy));

    bool  isPBR      = id != 2 && id != 3 && id != 4;
    bool  isLightmap = id != 4;

    #ifdef ADVANCED_MATERIALS

        material PBR = getMaterial(coord);

    #else

        float ao = filteredAO(vec3(coord, depth));

        if (isLightmap) {
            vec3 lmcAO = getLmCoordAO(coord);
            color     *= getLightmap(lmcAO.xy, lmcAO.z * ao);
        }
        color  = gamma(color);

    #endif


    #if FOG != 0

        if (depth < 1) {
            // Blend between FogColor and normal color based on distance
            vec3  viewPos  = toView(vec3(coord, depth) * 2 - 1);
            vec3  skyColor = gamma(getSkyColor(viewPos));

            color = mix(skyColor, color, fogFactor(viewPos));
        }


    #endif

    gl_FragData[0] = vec4(color, 1.0);
}