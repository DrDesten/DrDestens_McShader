#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform float rainStrength;
uniform vec3  fogColor;

uniform float lightBrightness;
uniform vec3  lightPosition;

in vec2 coord;
in vec3 normal;
in vec3 viewPos;
in vec4 glcolor;

#ifdef PHYSICALLY_BASED
/* DRAWBUFFERS:0231 */
#else
/* DRAWBUFFERS:023 */
#endif
void main() {
	vec4 color    = texture2D(texture, coord);
	vec3 lightPos = normalize(lightPosition);

	// "Volumetrics" (not actually)
	float passThroughAngle = saturate(dot(normalize(viewPos), lightPos));
	float vol_1 = passThroughAngle * 0.2 + 0.8;
	float vol_2 = sq(sq(passThroughAngle));

	// diffuse
	float diffuse = clamp(dot(normal, lightPos), 0, 1);

	color.rgb *= glcolor.rgb * (1 - sq(1 - lightBrightness));
	color.rgb *= (diffuse + 0.75) * (vol_1 + vol_2);
	color.a    = fstep(0.5, color.a);

	color.rgb = mix(color.rgb, fogColor * 0.1, rainStrength); // Weather Stuff

	gl_FragData[0] = color; //color
	gl_FragData[1] = vec4(normal, 1);   //normals
	gl_FragData[2] = vec4(codeID(52), vec3(1)); //block id (50, SSAO mask)
	#ifdef PHYSICALLY_BASED
	gl_FragData[3] = vec4(0, vec3(1));  // Reflectance
	#endif
}