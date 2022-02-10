

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                      MOTION BLUR AND BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"

uniform sampler2D colortex4;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

vec3 getBloomTilesPass2(sampler2D tex, vec2 coord) {

    float currentTile = ceil( -log2(1 - coord.x) ); // Gets the current tile
    // Log2(x) returns the exponent necessary to get to the coordinate.
    // we use 1-x because we want to start from the left
    // invert because the exponents are negative
    // ceil() to get the tile number

    float xOffset    = 1 - exp2( 1 - currentTile ); // Tbh I'm not even sure how this works (but it does)
    float tileScale  = exp2( currentTile );         // 2^tile gives us the scaling factor for each tile
    vec2  tileCoords = vec2(coord.x - xOffset, coord.y) * tileScale * (tileScale * BLOOM_TILE_PADDING + 1);
    tileCoords       = floor(tileCoords * screenSize) * screenSizeInverse;

    if (tileCoords != saturate(tileCoords)) {
        return vec3(0);
    }

    vec2  stepSize = screenSizeInverse;
    vec2  offset   = screenSizeInverse * 0.5;
    vec3  color    = vec3(0);
    for (int y = -1; y <= 2; y++) {
        
        float weight = gaussian_4[y + 1];
        vec2  offs   = vec2(0, y * stepSize.y - offset.y);

        color       += texture(tex, coord + offs).rgb * weight;

    }

    return color;
}

/* DRAWBUFFERS:4 */
void main() {
    //vec3 color = getAlbedo(coord);

    vec3 color = getBloomTilesPass2(colortex4, coord);

    //Pass everything forward
    gl_FragData[0] = vec4(color, 1);
}