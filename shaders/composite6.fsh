

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                      MOTION BLUR AND BLOOM
//////////////////////////////////////////////////////////////////////////////////////////////////////////


#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"

uniform sampler2D colortex4;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float blindness; 

vec3 vectorBlur(vec2 coord, vec2 blur, int samples) {
    if (length(blur) < screenSizeInverse.x) { return getAlbedo(coord); }

    vec3 col      = vec3(0);
    vec2 blurStep = blur / float(samples);
    vec2 sample   = coord;

    for (int i = 0; i < samples; i++) {
        col += getAlbedo_int(sample);
        sample += blurStep;
    }

    return col / float(samples);
}


vec3 readBloomTile(vec2 coord, float tile, float padding) {
    float tileScale = exp2( -tile - 1 );
    vec2  tileCoord = coord * tileScale / (exp2(tile + 1) * padding + 1);
    tileCoord.x    += 1 - exp2( -tile );

    return texture(colortex4, tileCoord).rgb;
}
vec3 readBloomTileBlur(vec2 coord, float initial_scale, float tile, float padding) {
    vec2 tileLocation = vec2(0);
    tileLocation.x    = 1 - exp2(-tile);
    tileLocation     += coord * exp2(-tile - 1);

    tileLocation     /= (initial_scale * .5);
    tileLocation.x   += padding * tile;

    vec3 color = vec3(0);
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {

            float weight = gaussian_5[x + 2] * gaussian_5[y + 2];
            vec2  offs   = vec2(x, y) * screenSizeInverse;

            vec2 sample  = tileLocation + offs;
            color       += texture(colortex4, sample).rgb * weight;

        }
    }

    return color;
}

/* DRAWBUFFERS:0 */
void main() {
    #ifdef MOTION_BLUR

        // Motion Blur dependent on player Movement and Camera
        vec3  clipPos      = vec3(coord, getDepth(coord)) * 2 - 1;
        vec3  prevCoord    = previousReproject(clipPos);

        vec2  motionBlurVector = (clamp(prevCoord.xy, -0.2, 1.2) - coord) * float(clipPos.z > 0.12) * MOTION_BLUR_STRENGTH;

        float ditherOffset     = (Bayer4(coord * screenSize) - 0.5) / MOTION_BLUR_SAMPLES;
        vec3  color            = vectorBlur(motionBlurVector * ditherOffset + coord, motionBlurVector, MOTION_BLUR_SAMPLES);

    #else

        vec3  color = getAlbedo(coord);

    #endif

    #ifdef BLOOM

        vec3 bloom = vec3(0);
        for (int i = 0; i < 6; i++) {
            bloom += readBloomTile(coord, i, 10 * screenSizeInverse.x);
        }
        bloom  = bloom / (6. * BLOOM_AMOUNT);
        bloom  = sq(bloom) * BLOOM_AMOUNT;
        color += bloom;
        //color = readBloomTile(coord, 2, 10 * screenSizeInverse.x);
        //color = texture(colortex4, coord).rgb;

    #endif

    //Pass everything forward
    FD0          = vec4(color, 1);
}