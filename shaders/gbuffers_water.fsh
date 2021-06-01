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

    // Reduce opacity of only water
    color.a -= color.a * 0.8 * float(blockId == 1001);
    
    gl_FragData[0] = color; // Color
    gl_FragData[1] = vec4(Normal, 1); // Normal
    gl_FragData[2] = vec4(vec3(blockId - 1000), 1); // Type (colortex4)
}