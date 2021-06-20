#version 130

#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/gamma.glsl"

#define WATER_NORMALS_AMOUNT 1.0					// "Fake" Wave strength 		[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

uniform float frameTimeCounter;

flat in float blockId;

in vec2 coord;
in vec3 worldPos;

in vec4 glcolor;
in mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector


vec3 noiseNormals(vec2 coord, float strength) {
    vec2  e = vec2(0.01, 0);
    float R = fbm(coord + e.xy, 2);
    float L = fbm(coord - e.xy, 2);
    float T = fbm(coord - e.yx, 2);
    float B = fbm(coord + e.yx, 2);

    vec3 n  = vec3((R-L) / e.x, (B-T) / e.x, 2);
    n.xy   *= strength;
    return normalize(n);
}
vec3 noiseNormalsOpt(vec2 coord, float strength) {
    vec2  e = vec2(0.01, 0);
    float C = fbm(coord,        3);
    float R = fbm(coord + e.xy, 3);
    float B = fbm(coord + e.yx, 3);

    vec3 n  = vec3((R-C) / e.x, (B-C) / e.x, 1);
    n.xy   *= strength;
    return normalize(n);
}


/* DRAWBUFFERS:024 */

void main(){
    vec4 color = texture(colortex0, coord) * glcolor;

    vec3 surfaceNormal = tbn[2];

    // Reduce opacity and saturation of only water
    if (blockId == 1001) {
        //color.rgb = mix(color.rgb, vec3(sum(color.rgb) / 10), 0.5);
        color.a *= 0;
        
        // "Fake" Waves
        vec2 seed = (worldPos.xz) + (frameTimeCounter * 0.5);
        vec3 noiseNormals = noiseNormals(seed, WATER_NORMALS_AMOUNT * 0.1);

        surfaceNormal = normalize(tbn * noiseNormals);
    }

    gamma(color.rgb);

    
    gl_FragData[0] = color; // Color
    gl_FragData[1] = vec4(surfaceNormal, 1); // Normal
    gl_FragData[2] = vec4(vec3(blockId - 1000), 1); // Type (colortex4)
}