

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                         DEPTH OF FIELD
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/stddef.glsl"

#include "/core/math.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"
#include "/lib/composite/normal.glsl"
#include "/lib/composite/id.glsl"
#include "/core/kernels.glsl"

#ifdef MOTION_BLUR
#include "/core/transform.glsl"
#endif

#ifdef BLOOM
const bool colortex0MipmapEnabled = true; //Enabling Mipmapping
#endif

vec2 coord = gl_FragCoord.xy * screenSizeInverse;


/////////////////////////////////////////////////////////////////////////////////////
//                              BLOOM & MOTION BLUR
/////////////////////////////////////////////////////////////////////////////////////

vec3 vectorBlur(vec2 coord, vec2 blur, int samples, float dither) {
    if (sqmag(blur) < sq(screenSizeInverse.x)) return getAlbedo(coord);

    vec3 col      = vec3(0);
    vec2 blurStep = blur / float(samples);
    vec2 sample   = blurStep * dither + coord;

    for (int i = 0; i < samples; i++) {
        col    += textureLod(colortex0, sample, 0).rgb;
        sample += blurStep;
    }

    return col / float(samples);
}

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
    vec2  stepSize = screenSizeInverse * tileScale;
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


/* DRAWBUFFERS:04 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1;

void main() {
    #if !defined BLOOM && !defined MOTION_BLUR
    discard;
    #endif

    #ifdef BLOOM
    vec3 bloom = getBloomTilesBlur(coord);
    #else
    vec3 bloom = vec3(0);
    #endif

    #ifdef MOTION_BLUR
    vec2 motionVector = motionBlur(vec3(coord, getDepth(coord))).xy;
    vec3 color        = vectorBlur(coord, motionVector, 4, Bayer4(gl_FragCoord.xy)); 
    #else 
    vec3 color = getAlbedo(coord);
    #endif

    //Pass everything forward
    FragOut0 = vec4(color,  1);
    FragOut1 = vec4(bloom,  1);
}
