#version 130

#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/gamma.glsl"

#define CHROM_ABERRATION    3      // Chromatic Aberration     [0 1 2 3 4 5 6 7 8 9 10]

#define SATURATION 1.2             // Saturation               [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

#define LENS_DISTORT        0.2    // Lens Distorsion          [0.0 0.2 0.35 0.5 0.75 1.0]
#define LENS_DISTORT_SCALE  1.2    // Lens Distorsion Scaling  [1.0 1.1 1.2 1.3 1.45]

varying vec2 coord;

uniform int frameCounter;

const float chromatic_aberration_amount = float(CHROM_ABERRATION) / 500;

/* DRAWBUFFERS:0 */

void Vignette(inout vec3 color) { //Darken Screen Borders
    float dist = distance(coord.st, vec2(0.5));

    dist = (dist * dist) * (dist * 1.5);

    color.rgb *= 1 - dist;
}

vec2 scaleCoord(vec2 coord, float scale) { //Scales Coordinates from Screen Center
    coord.st -= 0.5f; //Make 0/0 center of screen

    coord.st *= scale; //Scaling, divide to make larger number scale in

    //Fix Borders (mirror)
    //If the coordinates exeed maximum (x-Axis):
    if (coord.s > 0.5) {coord.s = 1 - coord.s;}
    if (coord.s < -0.5) {coord.s = -1 - coord.s;}
    //If the coordinates exeed maximum (y-Axis):
    if (coord.t > 0.5) {coord.t = 1 - coord.t;}
    if (coord.t < -0.5) {coord.t = -1 - coord.t;}


    coord.st += 0.5f; //Reverse translation
    return coord;
}

vec2 scaleCoord_f(vec2 coord, float scale) { //Scales Coordinates from Screen Center
    coord = (coord * scale) - (0.5 * (scale - 1));
    return clamp(coord, 0, 0.999999);
}

vec2 lensDistorsion(vec2 coord, float scale, float distorsion) { //Distorts Image
    float dist = distance(coord, vec2(0.5));
    dist = pow(dist, 2);

    coord = scaleCoord(coord, scale - (dist*distorsion));

    return coord;
}

vec3 radialBlur(vec2 coord, int samples, float amount) {
    vec3 col = vec3(0);
    for (int i = 0; i < samples; i++) {
        col += getAlbedo(scaleCoord_f(coord, 1 - ((float(i) / float(samples)) * amount)));
    }
    return col / float(samples);
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
    amount = distance(coord, vec2(0.5)) * amount;

    //Red Channel
    col.r     = radialBlur(scaleCoord_f(coord, 1.0 - amount), samples, amount).r;
    //Green Channel
    col.g     = radialBlur(coord, samples, amount).g;
    //Blue Channel
    col.b     = radialBlur(scaleCoord_f(coord, 1.0 + amount), samples, amount).b;

    return col;
}


vec3 luminanceNeutralize(vec3 col) {
    return (col * col) / (sum(col) * sum(col));
}


/* DRAWBUFFERS:0 */

void main() {
    #if CHROM_ABERRATION == 0
        vec3 color = getAlbedo(coord);
    #else
        vec3 color = ChromaticAbberation(coord, chromatic_aberration_amount);
    #endif


    color = saturation(color, SATURATION);

    //Vignette(color);

    color = invgamma(color);

    FD0 = vec4(color, 1.0);
}

