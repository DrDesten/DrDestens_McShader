#version 120

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

void main() {
	vec4 clipPos = ftransform();

	viewpos = getView();
	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN();
	
	if (mc_Entity.x == 1010 && coord.y < mc_midTexCoord.y) { // Waving Blocks
		vec4 pos = getPlayer() + vec4(cameraPosition, 0);
		pos.xz  += sin((pos.xz) + (frameTimeCounter * 1.5)) * .1;

		clipPos  = playerToClip(pos - vec4(cameraPosition, 0));
	}

	blockId = mc_Entity.x;
	glcolor = gl_Color;
	gl_Position  = clipPos;
}