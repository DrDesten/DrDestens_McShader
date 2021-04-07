#version 130

#include "/lib/framebuffer.glsl"
#include "/lib/skyColor.glsl"

varying vec2 texcoord;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;

void main() {
    vec2 coord = texcoord;

    vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

    vec3 color = getSkyColor(viewPos.xyz); //Get sky

    COLORTEX_0 = vec4(color, 1.0);
    COLORTEX_1 = vec4(0,0,0,1);
}