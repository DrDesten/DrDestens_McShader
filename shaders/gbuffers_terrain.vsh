#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/kernels.glsl"
#include "/core/vertex_transform.glsl"
#include "/lib/vertex_lighting.glsl"

attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;
attribute vec4 at_tangent;

uniform float frameTimeCounter;
uniform int   frameCounter;
uniform vec3  upPosition;

#ifdef TAA
    uniform vec2 taaOffset;
#endif

#ifdef OPTIMIZE_INTERPOLATION
    flat out mat3 tbn;
#else
    out mat3 tbn;
#endif

#ifdef PBR
    out vec3 viewpos;
#endif

flat out int blockId;
out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;


vec3 wavyPlants(vec3 worldPos, float amount) {
	vec2 time    = vec2(frameTimeCounter * 1.5, -frameTimeCounter * 2);
	vec2 sinArg  = worldPos.xz + worldPos.y * 5;
	worldPos.xz += sin((worldPos.xz) + time) * amount;
	worldPos.y  -= 1e-3; // Prevent Z-Fighting
	return worldPos;
}

void main() {

	gl_Position = ftransform();

	#ifdef PBR
	viewpos = getView();
	#endif
	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN(at_tangent);
	blockId = getID(mc_Entity);
	glcolor = gl_Color;

	if (!(1030 <= mc_Entity.x && mc_Entity.x <= 1032)) glcolor.a *= oldLighting(tbn[2], gbufferModelView);
	
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
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif


}