#version 120

#include "/lib/settings.glsl"
#include "/lib/vertex_transform.glsl"

attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;

uniform float frameTimeCounter;

flat varying float blockId;
varying vec3  viewpos;
varying vec2  lmcoord;
varying vec2  coord;

varying vec4 glcolor;

flat varying mat3 tbn;

vec3 wavyPlants(vec3 worldPos, float amount) {
	vec2 time    = vec2(frameTimeCounter * 1.5, -frameTimeCounter * 2);
	vec2 sinArg  = worldPos.xz + worldPos.y * 5;
	worldPos.xz += sin((worldPos.xz) + time) * amount;
	return worldPos;
}

void main() {
	vec4 clipPos = ftransform();

	viewpos = getView();
	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN();
	
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


	blockId = mc_Entity.x;
	glcolor = gl_Color;
	gl_Position  = clipPos;
}