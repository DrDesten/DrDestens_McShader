#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#if FOG != 0
#include "/core/vertex_transform.glsl"
#else
#include "/core/vertex_transform_simple.glsl"
#endif
#include "/core/kernels.glsl"

#ifdef TAA
    uniform vec2 taaOffset;
#endif

#if FOG != 0
out vec3 playerPos;
#endif

out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	
	#if FOG != 0
		playerPos = getPlayer();
	#endif

	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif
	
	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;
}