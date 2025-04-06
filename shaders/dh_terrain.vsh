#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/core/kernels.glsl"
#include "/core/vertex_transform.glsl"
#include "/lib/vertex_lighting.glsl"

#ifdef TAA
    uniform vec2 taaOffset;
#endif

flat out vec3 normal;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 worldPos;
flat out int materialId;

float getBlockShade(vec3 playerNormal) {
    playerNormal /= maxc(abs(playerNormal));

#if defined OVERWORLD
    const float brightnessLevels[6] = float[](
        0.8,  0.8, // +x, -x (east, west)
        1,    0.4, // +y, -y (up, down)
        0.65, 0.65 // +z, -z (south, north)
    );
#else 
    const float brightnessLevels[6] = float[](
        0.85, 0.85, // +x, -x (east, west)
        1,    1,    // +y, -y (up, down)
        0.7,  0.75  // +z, -z (south, north)
    );
#endif

    float components[6] = float[](
        saturate(playerNormal.x),
        saturate(-playerNormal.x),
        saturate(playerNormal.y),
        saturate(-playerNormal.y),
        saturate(playerNormal.z),
        saturate(-playerNormal.z)
    );

    float shade = 0;
    for (int i = 0; i < 6; i++) {
        shade += components[i] * brightnessLevels[i];
    }

    return shade;
}

void main() {
    glcolor     = gl_Color;
    lmcoord     = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    materialId  = dhMaterialId;
    gl_Position = getPosition();

    vec3 viewPos      = getView();
    vec3 viewNormal   = getNormal();
    vec3 playerPos    = toPlayer(viewPos);
    vec3 playerNormal = normalize(toPlayer(viewPos + viewNormal) - playerPos);
    worldPos          = toWorld(playerPos);

    float shade = getBlockShade(playerNormal);
    
    if (materialId == DH_BLOCK_LEAVES) {
        shade = (shade - 1) * 0.5 + 1;
    }

    if (worldPos.y > 500) {
        
        lmcoord.xy = vec2(0,1);

    }

    glcolor.a = shade;
    normal    = viewNormal;
    
	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif
}