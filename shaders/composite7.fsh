

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


vec3 getBloomTilesBlur(vec2 coord) {

    float currentTile = ceil( -log2(1 - coord.x) ); // Gets the current tile
    // Log2(x) returns the exponent necessary to get to the coordinate.
    // we use 1-x because we want to start from the left
    // invert because the exponents are negative
    // ceil() to get the tile number

    vec2  tileOffset = vec2(1 - exp2(1-currentTile));
    float tileScale  = exp2(currentTile);
    vec2  tileCoord  = (coord - tileOffset) * tileScale;

    if (tileCoord != saturate(tileCoord)) {
        return vec3(0);
    }

    float lod      = currentTile;
    vec2  stepSize = screenSizeInverse * (tileScale * 2);
    vec2  offset   = screenSizeInverse * (tileScale * 0.5);
    vec3  color    = vec3(0);
    for (int x = -1; x <= 2; x++) {
        for (int y = -1; y <= 2; y++) {
            
            float weight = gaussian_4[x + 1] * gaussian_4[y + 1];
            vec2  offs   = vec2(x, y) * stepSize - offset;

            color       += textureLod(colortex0, tileCoord + offs, lod).rgb * weight;

        }
    }

    return color;
}

/* DRAWBUFFERS:4 */

void main() {
    #ifdef BLOOM
    vec3 color = getBloomTilesBlur(coord);
    #else
    vec3 color = vec3(0);
    #endif

    //Pass everything forward
    gl_FragData[0]          = vec4(color,  1);
}
