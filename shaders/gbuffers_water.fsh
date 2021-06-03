#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/gamma.glsl"


flat in float blockId;

in vec3 Normal;
in vec2 coord;

/* DRAWBUFFERS:024 */

void main(){
    vec4 color       = texture(colortex0, coord);
    
    // Reduce opacity and saturation of only water
    if (blockId == 1001) {
        color.rgb = mix(color.rgb, vec3(sum(color.rgb) / 10), 0.8);
        color.a *= 0.5;
    }

    gamma(color.rgb);

    
    gl_FragData[0] = color; // Color
    gl_FragData[1] = vec4(Normal, 1); // Normal
    gl_FragData[2] = vec4(vec3(blockId - 1000), 1); // Type (colortex4)
}