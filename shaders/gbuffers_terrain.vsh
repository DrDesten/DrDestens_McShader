

#include "/lib/settings.glsl"
#include "/lib/vertex_transform.glsl"
#include "/lib/kernels.glsl"

attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;
attribute vec4 at_tangent;

uniform float frameTimeCounter;
uniform int frameCounter;

uniform vec2 screenSizeInverse;

varying float blockId;
#ifdef PHYSICALLY_BASED
varying vec3  viewpos;
#endif
varying vec2  lmcoord;
varying vec2  coord;

varying vec4 glcolor;

varying mat3 tbn;

vec3 wavyPlants(vec3 worldPos, float amount) {
	vec2 time    = vec2(frameTimeCounter * 1.5, -frameTimeCounter * 2);
	vec2 sinArg  = worldPos.xz + worldPos.y * 5;
	worldPos.xz += sin((worldPos.xz) + time) * amount;
	worldPos.y  -= 1e-3; // Prevent Z-Fighting
	return worldPos;
}

void main() {

	vec4 clipPos = ftransform();

	#ifdef PHYSICALLY_BASED
	viewpos = getView();
	#endif
	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN(at_tangent);
	
	#ifdef WAVY_BLOCKS

		if ((mc_Entity.x == 1010 || mc_Entity.x == 1011) && coord.y < mc_midTexCoord.y) { // Waving Blocks Upper Vertices

			vec4 pos  = getPlayer() + vec4(cameraPosition, 0);
			pos.xyz	  = wavyPlants(pos.xyz, .05);

			clipPos   = playerToClip(pos - vec4(cameraPosition, 0));
		}
		
		if (mc_Entity.x == 1012
		#ifdef WAVY_LEAVES
		 || mc_Entity.x == 1015
		#endif
		 ) { // Waving Blocks All Vertices

			vec4 pos  = getPlayer() + vec4(cameraPosition, 0);
			pos.xyz   = wavyPlants(pos.xyz, .05);

			clipPos   = playerToClip(pos - vec4(cameraPosition, 0));
		}

	#endif

	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif

	#ifdef TAA
		clipPos.xy += TAAOffsets[int( mod(frameCounter, 4) )] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif


	blockId     = mc_Entity.x;
	glcolor     = gl_Color;
	gl_Position = clipPos;

}