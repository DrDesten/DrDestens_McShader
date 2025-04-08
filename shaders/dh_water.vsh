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


out vec2 lmcoord;
out vec3 viewPos;
flat out vec3 normal;
flat out vec4 glcolor;
flat out int materialId;

void main() {
    lmcoord    = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor    = gl_Color;
    materialId = dhMaterialId;
    
    vec4 vertexPos = gl_Vertex;

#ifdef TAA
    vertexPos.xy += taaOffset * TAA_JITTER_AMOUNT * vertexPos.w * 2;
#endif

    // Move down to match vanilla
    if (materialId == DH_BLOCK_WATER) {
        vertexPos.y -= 1.8/16.0;
    }

    normal      = getNormal();
    viewPos     = getView(vertexPos);
    gl_Position = getPosition(vertexPos);
}