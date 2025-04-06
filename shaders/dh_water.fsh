uniform int worldTime;
uniform float frameTimeCounter;

#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"
#include "/core/math.glsl"

#include "/lib/gbuffers/basics.glsl"
#include "/lib/gbuffers/color.glsl"
#include "/lib/lightmap.glsl"
#include "/lib/pbr/lighting.glsl"

#include "/core/water.glsl"

#include "/core/dh/uniforms.glsl"
#include "/core/dh/transform.glsl"
#include "/core/transform.glsl"

uniform sampler2D depthtex0;
uniform float near;
uniform float far;
uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

#ifdef FOG
#include "/lib/sky.glsl"
#endif

in vec2 lmcoord;
flat in vec4 glcolor;
in vec3 viewPos;
flat in vec3 normal;
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
    vec3 lightmap  = vec3(lmcoord, 1);
    vec3 playerPos = toPlayer(viewPos);
    vec3 worldPos  = toWorld(playerPos);
    vec3 surfaceNormal = normal;

    // Discarding Logic
    
#ifdef DH_TRANSPARENT_DISCARD
    float borderTolerance = (materialId == DH_BLOCK_WATER ? 0 : 1e-5) + DH_TRANSPARENT_DISCARD_TOLERANCE;
    if ( discardDH(worldPos, borderTolerance) ) {
        discard;
    }
#else
    float fade = smoothstep( dhNearPlane, min(dhNearPlane * 2 + 32, far * 0.5), -viewPos.z ) - sq(Bayer8(gl_FragCoord.xy));
    if ( fade < 0 ) {
        discard;
    }
#endif

    float depth         = texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x;
    float dhDepth       = gl_FragCoord.z;
    vec3  dhScreenPos   = vec3(gl_FragCoord.xy * screenSizeInverse, dhDepth);
    vec3  dhViewPos     = screenToViewDH(dhScreenPos);
    float dhMappedDepth = backToScreen(dhViewPos).z;

    if (depth < 1 && depth < dhMappedDepth) {
        discard;
    }
    
    vec4 color   = glcolor;
    int  blockId = materialId == DH_BLOCK_WATER ? 10 : 0;

    if (materialId == DH_BLOCK_WATER) {
        
		mat3 tbn     = cotangentFrame(surfaceNormal, -viewPos, gl_FragCoord.xy * screenSizeInverse);
        vec3 viewDir = normalize(viewPos);
        
        #ifdef WATER_TEXTURE_VISIBLE
            color.rgb = sq(color.rgb * getCustomLightmap(lightmap, customLightmapBlend)) * 0.75;
        #else
            color.rgb          = vec3(0);
            color.a            = 0;
        #endif

        #if WATER_NORMALS != 0
            vec3  worldPos   = playerPos + cameraPosition;
            float surfaceDot = dot(viewDir, surfaceNormal);

            #if WATER_NORMALS == 1
                vec2  seed        = (worldPos.xz * WATER_NORMALS_SIZE) + (frameTimeCounter * 0.5);
                float blend       = saturate(map(abs(surfaceDot), 0.005, 0.2, 0.05, 1));
                vec3  waveNormals = noiseNormals(seed, WATER_NORMALS_AMOUNT * 0.1 * blend);
            #else 
                float blend       = saturate(-surfaceDot * 3);
                vec3  waveNormals = waterNormalsSine(worldPos, frameTimeCounter, WATER_NORMALS_AMOUNT * blend);
            #endif

            surfaceNormal = normalize(tbn * waveNormals);
        #endif

    }

    vec3 lightmapColor = getCustomLightmap(lightmap, customLightmapBlend);

    #ifdef WHITE_WORLD
    color.rgb = vec3(1);
    #endif

    color.rgb  = gamma(color.rgb);
    color.rgb *= lightmapColor;

#if FOG != 0

    float fog = getFogFactor(playerPos);
    color.rgb = mix(color.rgb, getFog(normalize(playerPos)), fog);

#endif

    FragOut0 = color; // Color
    FragOut1 = vec4(spheremapEncode(surfaceNormal), 1, 1); // Normal
    FragOut2 = vec4(codeID(blockId), vec3(1)); // Type 
	FragOut3 = vec4(lightmap, 1);
#ifdef PBR
	FragOut4 = vec4(0,0,0,1);
#endif
}