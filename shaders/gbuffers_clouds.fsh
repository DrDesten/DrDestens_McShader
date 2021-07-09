#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"

uniform sampler2D texture;

uniform vec3 shadowLightPosition;

varying vec2 coord;
varying vec3 normal;
varying vec3 viewPos;
varying vec4 glcolor;

/* DRAWBUFFERS:0231 */
void main() {
	vec4 color = texture2D(texture, coord);
	color.a = step(0.5, color.a);

	vec3 lightPos = normalize(shadowLightPosition);

	// "Volumetrics" (not actually)
	float passThroughAngle = dot(normalize(viewPos), lightPos);
	float vol_1 = passThroughAngle * 0.2 + 0.8;
	float vol_2 = sq(sq(max(passThroughAngle, 0)));

	// diffuse
	float diffuse = clamp(dot(normal, lightPos), 0, 1);

	color.rgb = vec3(diffuse + 0.75 * (vol_1 + vol_2)) * glcolor.rgb;

	gl_FragData[0] = color; //color
	gl_FragData[1] = vec4(normal, color.a);   //normals
	gl_FragData[2] = vec4(vec3(50), color.a); //block id (50, SSAO mask)
	gl_FragData[3] = vec4(0, vec3(1));        // Reflectance
}