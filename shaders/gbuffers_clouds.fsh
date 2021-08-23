#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"

uniform sampler2D texture;

uniform vec3  sunPosition;
uniform vec3  moonPosition;
uniform int   worldTime;

varying vec2 coord;
varying vec3 normal;
varying vec3 viewPos;
varying vec4 glcolor;

/* DRAWBUFFERS:0231 */
void main() {
	vec4 color = texture2D(texture, coord);

	vec3 lightPos = normalize((worldTime < 13000) ? sunPosition : moonPosition);

	// "Volumetrics" (not actually)
	float passThroughAngle = clamp(dot(normalize(viewPos), lightPos), 0, 1);
	float vol_1 = passThroughAngle * 0.2 + 0.8;
	float vol_2 = sq(sq(passThroughAngle));

	// diffuse
	float diffuse = clamp(dot(normal, lightPos), 0, 1);

	color.rgb = vec3(diffuse + 0.75 * (vol_1 + vol_2)) * glcolor.rgb;

	gl_FragData[0] = color; //color
	gl_FragData[1] = vec4(normal, 1);   //normals
	gl_FragData[2] = vec4(vec3(50), 1); //block id (50, SSAO mask)
	gl_FragData[3] = vec4(0, vec3(1));  // Reflectance
}