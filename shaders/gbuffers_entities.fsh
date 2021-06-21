#version 120

uniform int worldTime;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/lighting.glsl"
#include "/lib/labPBR13.glsl"
#include "/lib/gamma.glsl"

uniform sampler2D lightmap;
uniform sampler2D texture;
uniform vec4 entityColor;

varying vec3 normal;
varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = texture2D(texture, coord) * glcolor;
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	gamma(color.rgb);

	color *= texture2D(lightmap, lmcoord);

	gl_FragData[0] = color; //gcolor
}