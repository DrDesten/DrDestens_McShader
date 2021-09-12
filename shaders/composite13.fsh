

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/gamma.glsl"

#ifdef TAA
#include "/lib/kernels.glsl"
#include "/lib/transform.glsl"
uniform int frameCounter;
uniform sampler2D colortex5;
#endif

varying vec2 coord;

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

float depthToleranceAttenuation(float depthDiff, float peak) {
    return peak - abs(depthDiff - peak);
}
void neighborhoodClamp(vec2 coord, out vec3 minColor, out vec3 maxColor, float size) {
    minColor = vec3(1);
    maxColor = vec3(0);
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 sample = vec2(x, y) * size * screenSizeInverse + coord;
            vec3 color  = getAlbedo(sample);

            minColor = min(minColor, color);
            maxColor = max(maxColor, color);
        }
    }
} 

#ifdef TAA 
/* DRAWBUFFERS:05 */
#else
/* DRAWBUFFERS:0 */
#endif

void main() {
    #ifdef TAA
        vec2 unJitterCoord = coord + TAAOffsets[int( mod(frameCounter, 6) )] * TAA_JITTER_AMOUNT * screenSizeInverse;
    #else
        vec2 unJitterCoord = coord;
    #endif

    #if CHROMATIC_ABERRATION_AMOUNT != 0 && DOF_MODE == 0 
        vec3 color = ChromaticAbberation_HQ(unJitterCoord, chromaticAberrationBasic, 5);
    #else
        vec3 color = getAlbedo_int(unJitterCoord);
    #endif


    #ifdef TAA 

        float type              = floor(getType(unJitterCoord) + 0.5);
        float stencil           = float(type == 51 || type == 52);

        vec3  currentFrameColor = color;
        float depth             = getDepth_int(unJitterCoord);
        vec3  screenPos         = vec3(coord, depth);

        vec3  reprojectPos      = previousReproject(screenPos * 2 - 1);
        
        vec4  lastFrame         = texture(colortex5, reprojectPos.xy);
        vec3  lastFrameColor    = lastFrame.rgb;

        float movementPotential = max(lastFrame.a, stencil);
        float lastFrameStencil  = float(lastFrame.a > .01); // The stencil shows what was at some point a moveable object. Lower values correspond to previous points in time

        vec3 lowerThresh, higherThresh;
        neighborhoodClamp(coord, lowerThresh, higherThresh, 1);

        // Anti - Ghosting
        //////////////////////////////////////////////////////////////////////

        float boundsError     = float(saturate(reprojectPos.xy) != reprojectPos.xy);
        float spikeError      = float(any( lessThan(lastFrameColor + 0.005, lowerThresh) ) || any( greaterThan(lastFrameColor - 0.005, higherThresh) ));
        float moveErrorFine   = length( (coord - reprojectPos.xy) * screenSize ) * 0.25; 
        float moveErrorCoarse = moveErrorFine * 0.04;

        float blend   = saturate(boundsError + moveErrorCoarse + spikeError + TAA_BLEND);

        color         = mix(lastFrameColor, currentFrameColor, blend);
        vec3 TAAcolor = color;

    #endif
    
    color = saturation(color, SATURATION);

    color = reinhard_sqrt_tonemap(color * EXPOSURE, .5); // Tone mapping

    color = invgamma(color);

    FD0 = vec4(color, 1.0);
    #ifdef TAA 
    FD1 = vec4(TAAcolor, stencil + movementPotential * 0.5);
    #endif
}

