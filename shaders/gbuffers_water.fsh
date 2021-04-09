#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

varying vec3 Normal;
varying vec2 texcoord;

void main(){
    /* DRAWBUFFERS:024 */

    vec4 color       = texture(colortex0, texcoord);
    color.a *= 0.4;
    
    //color.rgb = Normal;
    
    gl_FragData[0] = color; // Color
    gl_FragData[1] = vec4(Normal * 0.5 + 0.5, 1); // Normal (mapping from -1/1 to 0/1)
    gl_FragData[2] = vec4(0,0,1,1); // Type (colortex4)
}