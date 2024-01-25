#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/transform.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"

#ifdef PBR
#include "/lib/pbr.glsl"
uniform sampler2D colortex3;
#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
#include "/lib/sky.glsl"

//////////////////////////////////////////////////////////////////////////////
//                     SKY RENDERING
//////////////////////////////////////////////////////////////////////////////

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;

void main() {
    float depth     = getDepth(coord);
    vec3  screenPos = vec3(coord, depth);
    vec3  color     = getAlbedo(coord);
    
    if (depth == 1) { // SKY

#ifdef OVERWORLD
        color += getSky(toPlayerEye(toView(screenPos * 2 - 1)));
#else
        color = getSky(toPlayerEye(toView(screenPos * 2 - 1)));
#endif

    } else { // NO SKY

#ifdef PBR

        vec4  samples[4];
        int   sampleIds[4];
        ivec2 sampleCoords[4];

        sampleCoords[0] = ivec2(gl_FragCoord.xy);
        sampleCoords[1] = ivec2(gl_FragCoord.xy) + ivec2(-1, 0);
        sampleCoords[2] = ivec2(gl_FragCoord.xy) + ivec2(0, -1);
        sampleCoords[3] = ivec2(gl_FragCoord.xy) + ivec2(-1, -1);

        if (sampleCoords[1].x == -1) sampleCoords[1].x = 1;
        if (sampleCoords[2].y == -1) sampleCoords[1].y = 1;
        if (sampleCoords[3].x == -1) sampleCoords[1].x = 1;
        if (sampleCoords[3].y == -1) sampleCoords[1].y = 1;

        for (int i = 0; i < 4; i++) {
            samples[i] = texelFetch(colortex3, sampleCoords[i], 0);
        }
        for (int i = 0; i < 4; i++) {
            sampleIds[i] = getCoordinateId(sampleCoords[i]);
        }

        MaterialTexture material = decodeMaterial(samples, sampleIds);

#endif

    }
    
    FragOut0 = vec4(color, 1.0);
}