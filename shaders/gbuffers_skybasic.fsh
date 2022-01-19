uniform mat4 gbufferModelViewInverse;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/skyColor.glsl"

uniform float wetness; 
uniform float rainStrength;

uniform vec3  sunPosition;
uniform vec3  moonPosition;

in vec3 viewpos;

const vec3 rgbWaveLengths  = vec3(680, 550, 440);
const vec3 rgbCoefficients = vec3(5.8e-6, 13.5e-6, 33.1e-6);

float densityRayleigh(float height) {
    const float H = 8500;
    return exp(-height/H);
}
float rayleighScatterOut(float dist, float coeff) {
    return exp(-coeff * dist);
}

vec2 sphereIntersect(vec3 rayPos, vec3 rayDir, vec3 spherePos, float sphereRadius) {
    vec3  L       = spherePos - rayPos;
    float tca     = dot(L, rayDir);
    float d       = sqrt(dot(L, L) - dot(tca, tca));
    if (d > sphereRadius) {return vec2(0);}
    float thc     = sqrt(sq(sphereRadius) - sq(d));

    float t0      = tca - thc;
    float t1      = tca + thc;

    return vec2(t0, t1);
}


float rayleigh(float dotp) {
    const float mult = 3 / (16 * PI);
    return mult * (1 + sq(dotp));
}
vec3 rayleigh(float dotp, vec3 coeff) {
    vec3 result = vec3(0);
    result.r = rayleigh(dotp) * coeff.r;
    result.g = rayleigh(dotp) * coeff.g;
    result.b = rayleigh(dotp) * coeff.b;
    return result;
}


/* DRAWBUFFERS:03 */
void main() {

    #ifdef OVERWORLD

        vec3  viewDir  = normalize(viewpos);
        
        float sunDot   = saturate(dot(viewDir, normalize(sunPosition)));
        sunDot         = pow(sunDot, 15) * .5;
        float moonDot  = saturate(dot(viewDir, normalize(moonPosition)));
        moonDot        = pow(moonDot, 20) * .25;

        vec3 color = getSkyColor5(viewpos, rainStrength); //Get sky
        color     *= 1 + sunDot + moonDot;

    #elif defined END

        vec3 color = getSkyColor5(viewpos, rainStrength); //Get sky

    #endif

    gamma(color.rgb);

    /* float dither = Bayer4(gl_FragCoord.xy) * (1./64) - (.5/64);
    color       += vec3(dither, dither, dither * 2); */

    gl_FragData[0] = vec4(color, 1.0);
    gl_FragData[1] = vec4(codeID(3), vec3(1));
}