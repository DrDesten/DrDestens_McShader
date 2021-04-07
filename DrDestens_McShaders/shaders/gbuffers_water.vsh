#version 130


#include "/lib/framebuffer_vertex.glsl"

uniform int frameCounter;
uniform vec3 cameraPosition;

varying vec3 Normal;
varying vec2 texcoord;

void main(){
    vec4 playerPos = vertexPlayer() + vec4(cameraPosition, 0);

    float zOffset    = (sin((playerPos.x * 0.5) + (float(frameCounter) * 0.05)) - 1) * 0.075;
    float zOffset2   = (sin((playerPos.z * 2) + (float(frameCounter) * 0.1)) - 1) * 0.05;

    playerPos += vec4(0, zOffset + zOffset2,0 ,0);

    vec4 clipPos = vertexWorldToClip(playerPos - vec4(cameraPosition, 0));

    gl_Position = clipPos;

    Normal = gl_NormalMatrix * gl_Normal;
    texcoord = gl_MultiTexCoord0.st;
}