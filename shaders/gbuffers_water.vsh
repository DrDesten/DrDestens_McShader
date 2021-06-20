#version 130


#include "/lib/math.glsl"
#include "/lib/framebuffer_vertex.glsl"

#define WAVY_WATER
#define WATER_WAVE_AMOUNT 1.0					// Physical Wave Height 			[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define WATER_NORMALS_AMOUNT 1.0					// "Fake" Wave strength 		[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

uniform float frameTimeCounter;
uniform vec3 cameraPosition;

// Optifine specifically looks for 'attribute' in order to parse mc_Entity.
// Since I am using opengl v130, I have to define 'attribute' as in to comply with the newer glsl syntax
#define attribute in
attribute vec4 at_tangent;
attribute vec4 mc_Entity;

flat out float blockId;
out vec2 coord;
out vec3 worldPos;
out vec4 glcolor;

out mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

void main(){

	#ifdef WAVY_WATER

		if (mc_Entity.x == 1001 && 1 == 0) {
			
			vec4 vertexPos = vertexPlayer();
			vec4 playerPos = vertexPos + vec4(cameraPosition, 0);

			// "Physical" Wave Offsets
			float zOffset    = (sin((playerPos.x * 0.1) + (frameTimeCounter * 3)) - 0.5) * 0.05;
			float zOffset2   = (sin((playerPos.z * 0.2) + (frameTimeCounter * 7.5)) - 0.5) * 0.025;
			// Appling them (y Direction aka "up")
			playerPos.y += (zOffset + zOffset2) * WATER_WAVE_AMOUNT;

			vec4 clipPos = vertexWorldToClip(playerPos - vec4(cameraPosition, 0));

			gl_Position = clipPos;
		}

		gl_Position = ftransform();
		
	#else

		gl_Position = ftransform();

	#endif

	vec3 normal = gl_NormalMatrix * gl_Normal;
	vec3 tangent = gl_NormalMatrix * (at_tangent.xyz / at_tangent.w);
	tbn = mat3(tangent, cross(tangent, normal), normal);
	
	vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
	vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;
	worldPos = feetPlayerPos + cameraPosition;

	blockId = mc_Entity.x;
    coord = gl_MultiTexCoord0.st;
	glcolor = gl_Color;
}