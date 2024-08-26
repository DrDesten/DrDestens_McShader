#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/kernels.glsl"

#if defined WORLD_CURVE || FOG != 0
    #include "/core/vertex_transform.glsl"
#else
    #include "/core/vertex_transform_simple.glsl"
#endif

#ifdef TAA
    uniform vec2 taaOffset;
#endif

out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;
#if FOG != 0
out vec3 playerPos;
#endif

void main() {

	gl_Position = ftransform();

	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif

	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif

	coord     = getCoord();
	lmcoord   = getLmCoord();
	glcolor   = gl_Color;
#if FOG != 0
	playerPos = getPlayer();
#endif
}