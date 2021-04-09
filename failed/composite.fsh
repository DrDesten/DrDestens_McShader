#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
 
varying vec4 texcoord;
varying vec3 lightVector;


/* DRAWBUFFERS:012 */

void main() {
    vec3 albedo = getAlbedo(texcoord.st);
    vec3 normal = getNormal(texcoord.st);
    float emission = getEmission(texcoord.st);

    float lightStrength = dot(normal, lightVector); //Dot product ~ Angle
    //lightStrength = max(0.1, lightStrength); //Dot product returns from -1 to 1 (under 0 = facing opposite)

    vec3 diffColor = albedo * lightStrength;

    COLORTEX_0 = vec4(vec3(lightStrength), 1);
}
