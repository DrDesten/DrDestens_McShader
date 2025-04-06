
#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/core/transform.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"

flat in vec3 normal;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 worldPos;
flat in int materialId;

#ifdef PBR
/* DRAWBUFFERS:01237 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;
layout(location = 4) out vec4 FragOut4;
#else
/* DRAWBUFFERS:0123 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;
layout(location = 2) out vec4 FragOut2;
layout(location = 3) out vec4 FragOut3;
#endif

void main() {
    bool isCloud =  worldPos.y > 500; 
#ifdef DH_TERRAIN_DISCARD
    if ( !isCloud && discardDH(worldPos, DH_TERRAIN_DISCARD_TOLERANCE) ) {
        discard;
    }
#endif
    
	vec3  lightmap     = vec3(lmcoord, glcolor.a);
    vec4  color        = vec4(glcolor.rgb, 1);

    if ( !isCloud ) {

        float texelDensity = max(
            maxc(abs(dFdx(worldPos))),
            maxc(abs(dFdy(worldPos)))
        );

        const float iter = 4;

        float dhNoise    = 0;
        float idealScale = (1./16) / texelDensity;
        float scale      = clamp(exp2(round(log2(idealScale))), 0, 4);

        vec3 globalRef = fract(worldPos / 1024) * 1024;
        for (float i = 1; i <= iter; i++) {
            vec3 seed   = floor(globalRef * scale + 1e-4) / scale;

            dhNoise   += rand(seed);
            scale     *= 2;
        }
        dhNoise /= iter;
        dhNoise  = (dhNoise * 0.25 + 0.9);

        color.rgb *= dhNoise;

    }

    color.rgb = gamma(color.rgb);
    
    if (lightmap.x > 14.5/15.) {
        color.rgb *= ( 1 + EMISSION_STRENGTH );
    }

	FragOut0 = color;
	FragOut1 = vec4(spheremapEncode(normal), 1, 1);
	FragOut2 = vec4(codeID(0), vec3(1));
	FragOut3 = vec4(lightmap, 1);
#ifdef PBR
	FragOut4 = vec4(0,0,0,1);
#endif
}