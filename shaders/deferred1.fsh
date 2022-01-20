#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/lighting_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform sampler2D colortex7;

/* DRAWBUFFERS:0 */
void main() {
    vec3  color = getAlbedo(ivec2(gl_FragCoord.xy));
    float id    = getID(ivec2(gl_FragCoord.xy));

    bool  isPBR      = id != 2 && id != 3 && id != 4;
    bool  isLightmap = id != 4;

    #ifdef ADVANCED_MATERIALS

        material PBR = getMaterial(coord);

    #else

        if (isLightmap) {
            vec3 lmcAO = getLmCoordAO(coord);
            color     *= getLightmap(lmcAO.xy, lmcAO.z);
        }
        color  = gamma(color);

    #endif

    //color = getNormal(coord) * 0.5 + 0.5;

    color = texture(colortex7, coord).rgb;

    gl_FragData[0] = vec4(color, 1.0);
}