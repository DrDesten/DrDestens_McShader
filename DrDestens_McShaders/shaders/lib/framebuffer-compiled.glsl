#define GLSLIFY 1
const int RGBA16       = 1;
const int RGBA8       = 1;
const int gcolorFormat = RGBA16;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA16;

uniform sampler2D gcolor;
uniform sampler2D colortex2;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform float viewHeight;
uniform float viewWidth;

#define COLORTEX_0 gl_FragData[0]
#define COLORTEX_1 gl_FragData[1]
#define COLORTEX_2 gl_FragData[2]

vec3 getAlbedo(in vec2 coord) {
    return texture(gcolor, coord).rgb;
}
vec3 getNormal(in vec2 coord) {
    return texture(colortex2, coord).rgb;
}
vec3 getDepth(in vec2 coord) {
    return texture(depthtex0, coord).rgb;
}
vec3 getNewDepth(in vec2 coord) {
    return texture(colortex1, coord).rgb;
}

float getEmission(in vec2 coord) { //Alpha = 1: Emission
    return texture(colortex1, coord).a;
}


// Vector-specific functions
float mean(vec4 vector) {
    return (vector.x + vector.y + vector.z + vector.w) * 0.25;
}
float mean(vec3 vector) {
    return (vector.x + vector.y + vector.z) * 0.333333333;
}
float mean(vec2 vector) {
    return (vector.x + vector.y) * 0.5;
}

float map(float from_min, float from_max, float to_min, float to_max, float value) {
    //map range function
    value -= from_min;
    value /= (from_max-from_min);
    value *= (to_max - to_min);
    value += to_min;
    return value;
}
float mapclamp(float from_min, float from_max, float to_min, float to_max, float value) {
    value = map(from_min, from_max, to_min, to_max, value);
    value = clamp(value, to_min, to_max);
    return value;
}
float mapexp(float from_min, float from_max, float to_min, float to_max, float value, float factor) {
    //map range function (non-linear)
    value -= from_min;
    value /= (from_max-from_min);

    if (value > 0) {value = pow(value, factor);}
    else {value = 0;}

    value *= (to_max - to_min);
    value += to_min;
    return value;
}
float mapexpNormalized(float from_min, float from_max, float value, float factor) {
    //map range function (non-linear)
    value -= from_min;
    value /= (from_max-from_min);

    if (value > 0) {return pow(value, factor);}
    else {return 0.0;}
}
