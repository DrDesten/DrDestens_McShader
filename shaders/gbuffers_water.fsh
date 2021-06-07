#version 130

#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/gamma.glsl"

#define WATER_NORMALS_AMOUNT 1.0					// "Fake" Wave strength 		[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

uniform float frameTimeCounter;

flat in float blockId;

in vec3 Normal;
in vec2 coord;
in vec3 worldPos;

/* DRAWBUFFERS:024 */

void main(){
    vec4 color       = texture(colortex0, coord);

    vec3 surfaceNormal = Normal;

    // Reduce opacity and saturation of only water
    if (blockId == 1001) {
        color.rgb = mix(color.rgb, vec3(sum(color.rgb) / 10), 0.8);
        color.a *= 0.5;
        

        // "Fake" Waves
        vec2 seed = (worldPos.xz * 0.5) + (frameTimeCounter);

        vec3 random3d = vec3(fbm(seed), fbm(vec2(seed.x + 100, seed.y)), 0);


        // Rotate a set Amount along a random axis
        surfaceNormal = rotateAxisAngle(random3d, 0.05 * WATER_NORMALS_AMOUNT) * surfaceNormal;
    }

    gamma(color.rgb);

    
    gl_FragData[0] = color; // Color
    gl_FragData[1] = vec4(surfaceNormal, 1); // Normal
    gl_FragData[2] = vec4(vec3(blockId - 1000), 1); // Type (colortex4)
}