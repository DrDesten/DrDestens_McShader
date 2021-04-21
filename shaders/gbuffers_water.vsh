#version 130


#include "/lib/framebuffer_vertex.glsl"

#define WAVY_WATER
#define WATER_WAVE_AMOUNT 1.0					// Physical Wave Height 			[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define WATER_NORMALS_AMOUNT 1.0					// "Fake" Wave strength 		[0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

uniform float frameTimeCounter;
uniform vec3 cameraPosition;

// Optifine specifically looks for 'attribute' in order to parse mc_Entity.
// Since I am using opengl v130, I have to define 'attribute' as in to comply with the newer glsl syntax
#define attribute in
attribute vec4 mc_Entity;

flat out float blockId;
out vec3 Normal;
out vec2 coord;

float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float noise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 x) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);
	// Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
	for (int i = 0; i < 2; ++i) {
		v += a * noise(x);
		x = rot * x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

void main(){

	#ifdef WAVY_WATER

		if (mc_Entity.x == 1001) {
			
			vec4 vertexPos = vertexPlayer();
			vec4 playerPos = vertexPos + vec4(cameraPosition, 0);

			// "Physical" Wave Offsets
			float zOffset    = (sin((playerPos.x * 0.1) + (frameTimeCounter * 3)) - 0.5) * 0.05;
			float zOffset2   = (sin((playerPos.z * 0.2) + (frameTimeCounter * 7.5)) - 0.5) * 0.025;
			// Appling them (y Direction aka "up")
			playerPos.y += (zOffset + zOffset2) * WATER_WAVE_AMOUNT;

			vec4 clipPos = vertexWorldToClip(playerPos - vec4(cameraPosition, 0));

			gl_Position = clipPos;

			// "Fake" Waves
			vec2 seed = playerPos.xz;
			seed = (playerPos.xz * 0.5) + (frameTimeCounter);

			vec3 random3d = vec3(noise(seed), noise(vec2(seed.x + 100, seed.y)), 0);
			vec3 surfaceNormal = gl_NormalMatrix * gl_Normal;

			// Rotate a set Amount along a random axis
			surfaceNormal = rotateAxisAngle(random3d, 0.05 * max(0, WATER_NORMALS_AMOUNT - abs(vertexPos.y * 0.03))) * surfaceNormal;
			Normal = surfaceNormal;

		} else {

			gl_Position = ftransform();
			Normal = gl_NormalMatrix * gl_Normal;
		}

	#else

		gl_Position = ftransform();
		Normal = gl_NormalMatrix * gl_Normal;

	#endif

	blockId = mc_Entity.x;
    coord = gl_MultiTexCoord0.st;
}