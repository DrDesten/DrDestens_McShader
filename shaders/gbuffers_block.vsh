#version 120

attribute vec4 mc_Entity;

varying float blockId;
varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();
	coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	blockId = mc_Entity.x;
	glcolor = gl_Color;
}