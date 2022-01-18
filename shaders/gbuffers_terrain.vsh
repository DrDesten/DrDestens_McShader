#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/vertex_transform.glsl"
#include "/lib/kernels.glsl"

attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;
attribute vec4 at_tangent;

uniform float frameTimeCounter;
uniform int   frameCounter;

uniform vec2 screenSizeInverse;

out float id;
out vec2  lmcoord;
out vec2  coord;
out vec4  glcolor;
out mat3  tbn;

vec3 wavyPlants(vec3 worldPos, float amount) {
	vec2 time    = vec2(frameTimeCounter * 1.5, -frameTimeCounter * 2);
	vec2 sinArg  = worldPos.xz + worldPos.y * 5;
	worldPos.xz += sin((worldPos.xz) + time) * amount;
	worldPos.y  -= 1e-3; // Prevent Z-Fighting
	return worldPos;
}

void main() {
	gl_Position = ftransform();

	coord    = getCoord();
	glcolor  = gl_Color;
	tbn      = getTBN(at_tangent);
	lmcoord  = getLmCoord();
	id       = getID(mc_Entity);
	
	#ifdef WAVY_BLOCKS

		// Waving Blocks Upper Vertices
		if ((mc_Entity.x == 1030 || mc_Entity.x == 1031) && coord.y < mc_midTexCoord.y) { 

			vec3 worldPos = getWorld();
			worldPos.xyz  = wavyPlants(worldPos, .05);

			gl_Position = playerToClip(vec4(worldPos - cameraPosition, 1));
		}

		// Waving Blocks All Vertices
		if (mc_Entity.x == 1032
		#ifdef WAVY_LEAVES
		 || mc_Entity.x == 1033
		#endif
		 ) {

			vec3 worldPos = getWorld();
			worldPos.xyz  = wavyPlants(worldPos, .05);

			gl_Position = playerToClip(vec4(worldPos - cameraPosition, 1));
		}

	#endif

	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif

	#ifdef TAA
		gl_Position.xy += TAAOffsets[int( mod(frameCounter, 9) )] * TAA_JITTER_AMOUNT * gl_Position.w * screenSizeInverse * 2;
	#endif


}