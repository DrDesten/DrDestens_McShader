

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/vertex_transform.glsl"
#include "/lib/kernels.glsl"

uniform int   frameCounter;
uniform float frameTimeCounter;
uniform vec2  screenSizeInverse;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;

varying float blockId;

varying vec2 coord;
varying vec2 lmcoord;
varying vec3 worldPos;
varying vec3 viewDir;

varying vec4 glcolor;
varying mat3 tbn;
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

void main(){

	vec4 clipPos 		= ftransform();
	vec4 viewPosition   = getView4();
	vec4 playerPosition = toPlayer(viewPosition);
	vec4 worldPosition  = vec4(playerPosition.xyz + cameraPosition, playerPosition.w);

	#ifdef WATER_WAVES

		if (mc_Entity.x == 1010) {

			// "Physical" Wave Offsets
			float zOffset    = (sin((worldPosition.x * 0.1) + (frameTimeCounter)) - 0.5) * 0.05;
			float zOffset2   = (sin((worldPosition.z * 0.2) + (frameTimeCounter * 3)) - 0.5) * 0.025;
			// Appling them (y Direction aka "up")
			worldPosition.y += (zOffset + zOffset2) * WATER_WAVE_AMOUNT;

			clipPos = playerToClip(vec4(worldPosition.xyz - cameraPosition, worldPosition.w));

		}

	#endif

	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif

	#ifdef TAA
		clipPos.xy += TAAOffsets[int( mod(frameCounter, 9) )] * TAA_JITTER_AMOUNT * clipPos.w * screenSizeInverse * 2;
	#endif

	gl_Position  = clipPos;

	tbn			 = getTBN(at_tangent);
	
	worldPos	 = worldPosition.xyz;
	viewDir      = normalize(viewPosition.xyz);

	blockId 	 = getID(mc_Entity);
    coord 		 = getCoord();
	lmcoord      = getLmCoord();
	glcolor 	 = gl_Color;

}