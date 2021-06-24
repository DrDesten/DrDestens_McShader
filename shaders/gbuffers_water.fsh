#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/skyColor.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D depthtex1;

uniform float frameTimeCounter;
uniform vec3  upPosition;

uniform float far;
uniform float near;
uniform int   isEyeInWater;

flat in float blockId;

in vec2 coord;
in vec3 worldPos;
in vec3 viewPos;

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
        color.rgb          = mix(color.rgb, vec3(sum(color.rgb) / 3), 0.5);
        color.a            = 0.11;

        float surfaceDot   = dot(normalize(viewPos), normalize(surfaceNormal));
        
        // "Fake" Waves
        vec2  seed         = (worldPos.xz * WATER_NORMALS_SIZE) + (frameTimeCounter * 0.5);
        float blend        = clamp(map(abs(surfaceDot), 0.01, 0.2, 5, 1), 1, 5);              // Reducing the normals at small angles to avoid high noise
        vec3  noiseNormals = noiseNormals(seed, WATER_NORMALS_AMOUNT * 0.1/blend);

        //color.a = 1;

        surfaceNormal      = normalize(tbn * noiseNormals);


        /* float absorption;
        if (isEyeInWater == 0) {
            
            vec2 screenCoord   = (gl_FragCoord.xy / ScreenSize);
            float terrainDepth = linearizeDepth(texture(depthtex1, screenCoord).x, near, far);
            float waterDepth   = linearizeDepth(gl_FragCoord.z, near, far);

            absorption = exp2(-(terrainDepth-waterDepth) * 0.1);
            color.rgb  = getAlbedo(screenCoord) * absorption;

        } */

        //color.rgb = absorption.xxx;
        //color.rgb = linearizeDepth(gl_FragCoord.z, near, far).xxx * 0.1;
        //color.rgb = (gl_FragCoord.xy / ScreenSize).yyy; 

        /* float fresnel     = customFresnel(normalize(viewPos), surfaceNormal, 0.02, 2, 3);
        vec4 Sky          = vec4( getSkyColor3( reflect(viewPos, surfaceNormal) ), 1);
        color             = mix(color, Sky, fresnel); */
    }

    gamma(color.rgb);

    
	if (blockId == 1005) {
		color.rgb = vec3(2);
	}

    
    gl_FragData[0] = color; // Color
    gl_FragData[1] = vec4(surfaceNormal, 1); // Normal
    gl_FragData[2] = vec4(vec3(blockId - 1000), 1); // Type (colortex4)
}