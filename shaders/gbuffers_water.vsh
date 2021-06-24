#version 130


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer_vertex.glsl"

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
out vec3 viewPos;

out vec4 glcolor;
out mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

void main(){

	vec4 viewPosition   = vertexViewPosition();
	vec4 playerPosition = vertexPlayer(viewPosition);
	vec4 worldPosition  = playerPosition + vec4(cameraPosition, 0);

	#ifdef WATER_WAVES

		if (mc_Entity.x == 1001) {

			// "Physical" Wave Offsets
			float zOffset    = (sin((worldPosition.x * 0.1) + (frameTimeCounter)) - 0.5) * 0.05;
			float zOffset2   = (sin((worldPosition.z * 0.2) + (frameTimeCounter * 3)) - 0.5) * 0.025;
			// Appling them (y Direction aka "up")
			worldPosition.y += (zOffset + zOffset2) * WATER_WAVE_AMOUNT;

			vec4 clipPos = vertexWorldToClip(worldPosition - vec4(cameraPosition, 0));

			gl_Position = clipPos;

		} else {

			gl_Position = ftransform();

		}
	
	#else

		gl_Position = ftransform();

	#endif

	vec3 normal  = gl_NormalMatrix * gl_Normal;
	vec3 tangent = gl_NormalMatrix * (at_tangent.xyz / at_tangent.w);
	tbn			 = mat3(tangent, cross(tangent, normal), normal);
	
	worldPos	 = worldPosition.xyz + gbufferModelViewInverse[3].xyz;
	viewPos      = viewPosition.xyz;

	blockId 	 = mc_Entity.x;
    coord 		 = gl_MultiTexCoord0.st;
	glcolor 	 = gl_Color;

}