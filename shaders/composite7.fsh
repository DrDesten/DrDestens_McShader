

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         DEPTH OF FIELD
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"

const bool colortex0MipmapEnabled = true; //Enabling Mipmapping

vec2 coord = gl_FragCoord.xy * screenSizeInverse;


/////////////////////////////////////////////////////////////////////////////////////
//                              BLOOM
/////////////////////////////////////////////////////////////////////////////////////

vec3 getBloomTiles(vec2 coord, float scale, int tiles, float padding) {

    vec2 bloomCoord = coord * scale;
    
    for (int i = 1; i < tiles; i++) {

        float padd = padding * exp2(i-1) * scale;

        // Check if the x-coordinate exceeds 1 (out of bounds)
        if (bloomCoord.x > 1 + padd) {
            // Bring back by 1 (back into bounds)
            bloomCoord.x -= 1 + padd;
            // Half the size of the tile
            bloomCoord   *= 2;
        } else {
            break;
        }

    }
    if (bloomCoord != saturate(bloomCoord)) {
        return vec3(0);
    }

    return texture(colortex0, bloomCoord).rgb;
}
vec3 getBloomTilesBlur(vec2 coord, float tiles, float padding) {

    float currentTile = ceil( -log2(1 - coord.x) ); // Gets the current tile
    // Log2(x) returns the exponent necessary to get to the coordinate.
    // we use 1-x because we want to start from the left
    // invert because the exponents are negative
    // ceil() to get the tile number

    float xOffset    = 1 - exp2( 1 - currentTile ); // Tbh I'm not even sure how this works (but it does)
    float tileScale  = exp2( currentTile );         // 2^tile gives us the scaling factor for each tile
    vec2  tileCoords = vec2(coord.x - xOffset, coord.y) * tileScale * (tileScale * padding + 1);

    if (tileCoords != saturate(tileCoords)) {
        return vec3(0);
    }

    vec2 stepSize = screenSizeInverse * tileScale * 1.5;
    vec3 color    = vec3(0);
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            
            float weight = gaussian_5[x + 2] * gaussian_5[y + 2];
            vec2  offs   = vec2(x, y) * stepSize;

            color       += textureLod(colortex0, tileCoords + offs, floor(currentTile + 0.5)).rgb * weight;

        }
    }

    return color;
}

vec3 getBloomTilesBlur_opt(vec2 coord, float tiles, float padding) {

    float currentTile = ceil( -log2(1 - coord.x) ); // Gets the current tile
    // Log2(x) returns the exponent necessary to get to the coordinate.
    // we use 1-x because we want to start from the left
    // invert because the exponents are negative
    // ceil() to get the tile number

    float xOffset    = 1 - exp2( 1 - currentTile ); // Tbh I'm not even sure how this works (but it does)
    float tileScale  = exp2( currentTile );         // 2^tile gives us the scaling factor for each tile
    vec2  tileCoords = vec2(coord.x - xOffset, coord.y) * tileScale * (tileScale * padding + 1);
    tileCoords       = floor(tileCoords * screenSize) * screenSizeInverse;

    if (tileCoords != saturate(tileCoords)) {
        return vec3(0);
    }

    float lod      = floor(currentTile + 0.5);
    vec2  stepSize = screenSizeInverse * (tileScale * 2);
    vec2  offset   = screenSizeInverse * (tileScale * 0.5);
    vec3  color    = vec3(0);
    for (int x = -1; x <= 2; x++) {
        for (int y = -1; y <= 2; y++) {
            
            float weight = gaussian_4[x + 1] * gaussian_4[y + 1];
            vec2  offs   = vec2(x, y) * stepSize - offset;

            color       += textureLod(colortex0, tileCoords + offs, lod).rgb * weight;

        }
    }

    return color;
}

vec3 getBloomTilesPass1(vec2 coord, float tiles, float padding) {

    float currentTile = ceil( -log2(1 - coord.x) ); // Gets the current tile
    // Log2(x) returns the exponent necessary to get to the coordinate.
    // we use 1-x because we want to start from the left
    // invert because the exponents are negative
    // ceil() to get the tile number

    float xOffset    = 1 - exp2( 1 - currentTile ); // Tbh I'm not even sure how this works (but it does)
    float tileScale  = exp2( currentTile );         // 2^tile gives us the scaling factor for each tile
    vec2  tileCoords = vec2(coord.x - xOffset, coord.y) * tileScale * (tileScale * padding + 1);
    tileCoords       = floor(tileCoords * screenSize) * screenSizeInverse;

    if (tileCoords != saturate(tileCoords)) {
        return vec3(0);
    }

    float lod      = floor(currentTile + 0.5);
    vec2  stepSize = screenSizeInverse * tileScale;
    vec2  offset   = stepSize * 0.5;
    vec3  color    = vec3(0);
    for (int x = -1; x <= 2; x++) {
            
        float weight = gaussian_4[x + 1];
        vec2  offs   = vec2(x * stepSize.x - offset.x, 0);

        color       += textureLod(colortex0, tileCoords + offs, lod).rgb * weight;

    }

    return color;
}

/* DRAWBUFFERS:4 */

void main() {
    //vec3 color = vec3(0);

    vec3 color = getBloomTilesPass1(coord, 1, 0.01);

    //Pass everything forward
    gl_FragData[0]          = vec4(color,  1);
}
