#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/kernels.glsl"
#include "/core/vertex_transform.glsl"
#include "/lib/vertex_lighting.glsl"

#include "/core/water.glsl"

#ifdef TAA
    uniform vec2 taaOffset;
#endif

uniform float frameTimeCounter;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;

OPT_FLAT out mat3 tbn;

flat out int blockId;
out vec3 worldPos;
out vec3 viewDir;
out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;

void main(){

	gl_Position    = ftransform();
	vec3 viewPos   = getView();
	vec3 playerPos = toPlayer(viewPos);
	worldPos       = playerPos + cameraPosition;

	#ifdef WATER_WAVES

		if (mc_Entity.x == 1010) {
            worldPos.y += waterVertexOffset(worldPos, frameTimeCounter) * WATER_WAVE_AMOUNT;
			gl_Position = playerToClip(vec4(worldPos - cameraPosition, 1));
		}

	#endif

	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif

	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif

	tbn         = getTBN(at_tangent);
	viewDir     = normalize(viewPos.xyz);
	blockId     = getID(mc_Entity);
    coord       = getCoord();
	lmcoord     = getLmCoord();
	glcolor     = gl_Color;
	glcolor.a  *= oldLighting(tbn[2], gbufferModelView);
}