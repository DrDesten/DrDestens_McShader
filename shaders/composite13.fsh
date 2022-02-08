

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"

#ifdef TAA
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
uniform int taaIndex;
uniform sampler2D colortex5;
#endif

uniform sampler2D colortex4;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;


void Vignette(inout vec3 color) { //Darken Screen Borders
    float dist = distance(coord.st, vec2(0.5));

    dist = (dist * dist) * (dist * 1.5);

    color.rgb *= 1 - dist;
}

vec2 scaleCoord_f(vec2 coord, float scale) { //Scales Coordinates from Screen Center
    //coord = (coord * scale) - (0.5 * (scale - 1));
    coord = scale * (coord - 0.5) + 0.5;
    return clamp(coord, 0, 0.999999);
}

vec2 lensDistorsion(vec2 coord, float scale, float distorsion) { //Distorts Image
    float dist = distance(coord, vec2(0.5));
    dist = pow(dist, 2);

    coord = mirrorClamp(coord * (scale - (dist*distorsion)));

    return coord;
}

vec3 radialBlur(vec2 coord, float samples, float amount) {
    vec3  col  = vec3(0);
    float sInv = 1 / samples;
    float mult = sInv * amount;
    for (float i = 0; i < samples; i++) {
        col += getAlbedo(scaleCoord_f(coord, (-i * mult) + 1));
    }
    return col * sInv;
}

vec3 ChromaticAbberation(vec2 coord, float amount) {
    vec3 col;
    amount = distance(coord, vec2(0.5)) * amount;

    //Red Channel
    col.r     = texture(colortex0, scaleCoord_f(coord, 1.0 - amount)).r;
    //Green Channel
    col.g     = texture(colortex0, coord).g;
    //Blue Channel
    col.b     = texture(colortex0, scaleCoord_f(coord, 1.0 + amount)).b;

    return col;
}

vec3 ChromaticAbberation_HQ(vec2 coord, float amount, int samples) {
    vec3 col;
    amount = sqmag(coord - 0.5) * amount;

    float dither = (Bayer4(coord * screenSize) * .75 + .5);

    //Red Channel
    col.r     = radialBlur(scaleCoord_f(coord, 1.0 - amount * dither), samples, amount).r;
    //Green Channel
    col.g     = radialBlur(coord, samples, amount).g;
    //Blue Channel
    col.b     = radialBlur(scaleCoord_f(coord, 1.0 + amount * dither), samples, amount).b;

    return col;
}

vec3 luminanceNeutralize(vec3 col) {
    return (col * col) / (sum(col) * sum(col));
}

// TONEMAPPING
/////////////////////////////////////////////////////////////////////////////////////////

vec3 reinhard_tonemap(vec3 color, float a) {
    return color / (a + color);
}
vec3 reinhard_luminance_tonemap(vec3 color, float a) {
    float l = luminance(color);
    return color / (a+l);
}
vec3 reinhard_jodie_tonemap(vec3 color, float a) {
    float l   = luminance(color);
    vec3 tmc  = color / (color + a);
    return mix(color / (l+a), tmc, tmc);
}
vec3 reinhard_sqrt_tonemap(vec3 color, float a) {
    return color / sqrt(color * color + a);
}


vec3 unreal_tonemap(vec3 color) {
  return color / (color + 0.155) * 1.019;
}


vec3 exp_tonemap(vec3 color, float a) {
    return 1 - exp(-color * a);
}



float PeakAttenuation(float depthDiff, float peak) {
    return peak - abs(depthDiff - peak);
}
vec3 readBloomTile(vec2 coord, float tile, float padding) {
    float tileScale = exp2( -tile - 1 );
    vec2  tileCoord = coord * tileScale / (exp2(tile + 1) * padding + 1);
    tileCoord.x    += 1 - exp2( -tile );

    return texture(colortex4, tileCoord).rgb;
}

/* DRAWBUFFERS:0 */
void main() {

    #if CHROMATIC_ABERRATION != 0
        vec3 color = ChromaticAbberation_HQ(coord, chromaticAberrationSimple, 5);
    #else
        vec3 color = getAlbedo(coord);
    #endif

    //color = readBloomTile(coord, 5, 0.01);

    #if TONEMAP == 1
    color = reinhard_sqrt_tonemap(color * EXPOSURE, .5); // Tone mapping
    color = gamma_inv(color);
    #elif TONEMAP == 2
    color = unreal_tonemap(color * EXPOSURE); // Tone mapping
    #endif

    #if CONTRAST != 0
    color = contrast(color, contrastValue);
    #endif
    #if SATURATION != 50
    color = saturation(color, saturationValue);
    #endif

    gl_FragData[0] = vec4(color, 1.0);
}

