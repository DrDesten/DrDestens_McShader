#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/transform.glsl"
#include "/lib/skyColor.glsl"
#include "/lib/gamma.glsl"

#ifdef FAST_SKY
    in vec3 skyColor;
#endif
in vec2 coord;

const vec3 rgbWaveLengths = vec3(680, 550, 440);
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


/* DRAWBUFFERS:04 */
void main() {

    #ifdef FAST_SKY

        vec3 color = skyColor;

    #else

        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1);
        vec3 viewPos = toView(screenPos * 2.0 - 1.0);

        vec3 color = getSkyColor3(viewPos); //Get sky

    #endif

    /* float dotp = max(dot(normalize(viewPos), normalize(sunPosition)), 0);
    color = rayleigh(dotp, vec3(2, 1, 2));

    vec2 si = sphereIntersect(vec3(0,6371000 + (cameraPosition.y * 100),0), normalize(toPlayerEye(viewPos)), vec3(0,0,0), 6471000);
    si = max(si, vec2(0));
    float gradient = max(si.y, si.x) / 10000000;
    gradient = clamp(gradient, 0, 1);

    color.rgb = mix(vec3(0.5,0.5,1), vec3(0.25,0.25,0.5), gradient); */

    gamma(color);

    FD0 = vec4(color, 1.0);
    FD1 = vec4(vec3(0), 1);
}