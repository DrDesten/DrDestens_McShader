#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gamma.glsl"

varying vec2 coord;

uniform int frameCounter;

uniform sampler2D colortex4;
#ifdef TAA
uniform sampler2D colortex5;
#endif

const float chromatic_aberration_amount = float(CHROM_ABERRATION) / 300;


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
    vec2 tmp = coord - .5;
    amount = dot(tmp, tmp) * amount;

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



#ifdef TAA 
/* DRAWBUFFERS:05 */
#else
/* DRAWBUFFERS:0 */
#endif

void main() {
    #ifdef TAA
        vec2 unJitterCoord = coord + blue_noise_disk[int( mod(frameCounter, 64) )] * screenSizeInverse;
    #else
        vec2 unJitterCoord = coord;
    #endif

    #if CHROM_ABERRATION == 0
        vec3 color = getAlbedo_int(unJitterCoord);
    #else
        vec3 color = ChromaticAbberation_HQ(unJitterCoord, chromatic_aberration_amount, 5);
    #endif

    color = saturation(color, SATURATION);

    color = reinhard_sqrt_tonemap(color * EXPOSURE, .5); // Tone mapping

    color = invgamma(color);

    #ifdef TAA 

        vec3  currentFrameColor = color;
        float depth             = getDepth_int(unJitterCoord);

        vec3  lastFrameColor    = texture(colortex5, coord).rgb;
        float lastFrameDepth    = pow(texture(colortex5, coord).a, 1./6.);

        float blend = clamp((abs(depth - lastFrameDepth) * 50) + (sqmag(currentFrameColor - lastFrameColor) * 0.5 + 0.1), 0, 1);

        color = mix(lastFrameColor, currentFrameColor, blend);
        //color = abs(depth - lastFrameDepth) * vec3(50);
        //color = length(currentFrameColor - lastFrameColor).xxx * 0.01;

    #endif


    FD0 = vec4(color, 1.0);
    #ifdef TAA 
    FD1 = vec4(color, pow(depth, 6));
    #endif
}

