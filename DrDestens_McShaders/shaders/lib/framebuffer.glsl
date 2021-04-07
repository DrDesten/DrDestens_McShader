uniform sampler2D colortex0; // Color
uniform sampler2D colortex1; // Linear Depth
uniform sampler2D colortex2; // Normals

uniform sampler2D colortex4; // Type (Blue = Water; White = sky)
//uniform sampler2D colortex5; // View Direction
uniform sampler2D depthtex0;

uniform float viewHeight;
uniform float viewWidth;

#define COLORTEX_0 gl_FragData[0]
#define COLORTEX_1 gl_FragData[1]
#define COLORTEX_2 gl_FragData[2]


ivec2 convertIntCoords(vec2 coord, float x, float y) {
    return ivec2(coord.x * x, coord.y * y);
}
vec2 blurOffset(vec2 coord, float lod) {
    return coord + (vec2(1 / viewWidth, 1 / viewHeight) * 0.5 * (lod + 1));
}


vec3 getAlbedo(in vec2 coord) {
    return texelFetch(colortex0, convertIntCoords(coord, viewWidth, viewHeight), 0).rgb;
}
vec3 getAlbedo_interpolated(in vec2 coord) {
    return texture(colortex0, coord).rgb;
}

vec3 getNormal(in vec2 coord) {
    return normalize(texture(colortex2, coord).rgb * 2 - 1);
}

float getDepth(in vec2 coord) {
    return texelFetch(depthtex0, convertIntCoords(coord, viewWidth, viewHeight), 0).x;
}
float getDepth_interpolated(in vec2 coord) {
    return texture(depthtex0, coord).x;
}
float getLinearDepth(in vec2 coord) {
    return texture(colortex1, coord).x;
}

vec3 getType(in vec2 coord) {
    return texelFetch(colortex4, convertIntCoords(coord, viewWidth, viewHeight), 0).rgb;
}
vec3 getType_interpolated(in vec2 coord) {
    return texture(colortex4, coord).rgb;
}
/*
vec3 getViewPosition(in vec2 coord) {
    return texture(colortex5, coord).xyz;
} */

float getEmission(in vec2 coord) { //Alpha = 1: Emission
    return texture(colortex1, coord).a;
}


float sinf(float x) {
    x *= 0.159155;
    x -= floor(x);
    float xx = x * x;
    float y = -6.87897;
    y = y * xx + 33.7755;
    y = y * xx - 72.5257;
    y = y * xx + 80.5874;
    y = y * xx - 41.2408;
    y = y * xx + 6.28077;
    return x * y;
}
float cosf(float x) {
    return sinf(x + 1.5708);
}


////////////////////////////////////////////////////////////////////////
// Randomization and Dither Patterns

const float PHI = 1.61803398874989484820459;
float randf_01(vec2 xy){
    xy = fract(xy);
    return fract(dot(xy, xy * PHI) * 324975.689);
}

float rand_01(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
float rand_11(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) * 2 - 1;
}

////////////////////////////////////////////////////////////////////////
// Vector-specific functions

mat3 rotateAxisAngle(vec3 u, float angleRadians) {
    float sinA = sinf( angleRadians );
    float cosA = cosf( angleRadians );
    float oneMinusCosA = 1.0f - cosA;

    return mat3( (u.x * u.x * oneMinusCosA) + cosA,
                 (u.y * u.x * oneMinusCosA) - (sinA * u.z), 
                 (u.z * u.x * oneMinusCosA) + (sinA * u.y),
                 (u.x * u.y * oneMinusCosA) + (sinA * u.z),  
                 (u.y * u.y * oneMinusCosA) + cosA,      
                 (u.z * u.y * oneMinusCosA) - (sinA * u.x),
                 (u.x * u.z * oneMinusCosA) - (sinA * u.y),  
                 (u.y * u.z * oneMinusCosA) + (sinA * u.x),  
                 (u.z * u.z * oneMinusCosA) + cosA 
                );
}

mat3 rotateAlign( vec3 v1, vec3 v2) {
    vec3 axis = cross( v1, v2 );

    float cosA = dot( v1, v2 );
    float k = 1.0f / (1.0f + cosA);

    mat3 result = mat3( 
        (axis.x * axis.x * k) + cosA,
        (axis.y * axis.x * k) - axis.z, 
        (axis.z * axis.x * k) + axis.y,
        (axis.x * axis.y * k) + axis.z,  
        (axis.y * axis.y * k) + cosA,      
        (axis.z * axis.y * k) - axis.x,
        (axis.x * axis.z * k) - axis.y,  
        (axis.y * axis.z * k) + axis.x,  
        (axis.z * axis.z * k) + cosA 
    );

    return result;
}

vec2 randVector2d(vec2 seed) {
    return vec2(rand_11(vec2(seed.x)), rand_11(vec2(seed.y)));
}
vec3 randVector3d(vec2 seed) {
    float rand1 = rand_11(seed);
    float rand2 = rand_11(vec2(rand1));
    return vec3(rand2, rand_11(vec2(rand2)), rand1);
}

float mean(vec2 vector) {
    return (vector.x + vector.y) * 0.5;
}
float mean(vec3 vector) {
    return (vector.x + vector.y + vector.z) * 0.333333333333;
}
float mean(vec4 vector) {
    return ((vector.x + vector.y) + (vector.z + vector.w)) * 0.25;
}

float sum(vec2 v) {
    return v.x + v.y;
}
float sum(vec3 v) {
    return v.x + v.y + v.z;
}
float sum(vec4 v) {
    return (v.x + v.y) + (v.z + v.w);
}

vec2 midpoint(vec2 v1, vec2 v2) {
    return (v1 + v2) * 0.5;
}
vec3 midpoint(vec3 v1, vec3 v2) {
    return (v1 + v2) * 0.5;
}
vec4 midpoint(vec4 v1, vec4 v2) {
    return (v1 + v2) * 0.5;
}


float angleBetween(vec3 v1, vec3 v2) {
    return acos(dot(normalize(v1), normalize(v2)));
}


/////////////////////////////////////////////////////////////////////////////////
//                              OTHER FUNCTIONS

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}
float mapclamp(float value, float from_min, float from_max, float to_min, float to_max) {
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

vec2 convertPolarCartesian(vec2 coord) {
    return vec2(coord.x * cos(coord.y), coord.x * sin(coord.y));
}

float linearizeDepth(float d,float nearPlane,float farPlane) {
    d = 2.0 * d - 1.0; // Convert to NDC (normalized device coordinates)
    return 2.0 * nearPlane * farPlane / (farPlane + nearPlane - d * (farPlane - nearPlane));
}
vec3 linearize(vec3 p, float nearPlane, float farPlane) {
    return vec3(
        linearizeDepth(p.x, nearPlane, farPlane),
        p.y,
        p.z
    );
}
float schlickFresnel(vec3 viewRay, vec3 normal, float refractiveIndex, float baseReflectiveness) {
    //Schlick-Approximation of fresnel
    float R0 = (1 - refractiveIndex) / (1 + refractiveIndex);
    R0 *= R0;

    float cosAngle = dot(viewRay, normal);
    float reflectiveness = R0 + ( (1 - R0) * pow(1 - cosAngle, 5) );
    reflectiveness = 1 - reflectiveness;
    reflectiveness = clamp(reflectiveness, 0, 1) + baseReflectiveness;
    return reflectiveness;
}
float customFresnel(vec3 viewRay, vec3 normal, float bias, float scale, int power) {
    float reflectiveness = clamp(bias + scale * pow(1.0 + dot(viewRay, normal), power), 0, 1); 
    return reflectiveness;
}


/////////////////////////////////////////////////////
//                   Color Functions



/* Snipplets for later

// TAA REPROJECTION

//depth is raw depth buffer
//coord is texture coordinates of fullscreen quad (composite yo)
vec2 taa_reproject(vec2 coord, float depth) 
{
    //Clip space
    vec4 pos = vec4(coord, depth, 1.0) * 2.0 - 1.0;

    //View space
    pos = gbufferProjectionInverse * pos;
    pos /= pos.w;

    //World space
    pos = gbufferModelViewInverse * pos;

    //Previous position
    vec4 prev_pos = pos + vec4(cameraPosition-previousCameraPosition, 0.0);
    
    //World to view space
    prev_pos = gbufferPreviousModelView * prev_pos;
    
    //View to projection space
    prev_pos = gbufferPreviousProjection * prev_pos;

    //Projection to UV space
    return (prev_pos.xy / prev_pos.w) * 0.5 + 0.5;
}


// SKY GRADIENT

vec3 dir = normalize(eyePlayerPos); //Get view direction in world space (chech ;position in bot channel to understand what eyePlayerPos is
vec3 sky_up = vec3(0.05, 0.2, 0.5); //Color of upper part of sky
vec3 sky_down = vec3(0.10, 0.40, 1.0); //Color of bottom part of sky

if (texture2D(depthtex0, texcoord).r == 1.0f)    //Check depth, if it's 1.0 - then it's sky.
    color = mix(sky_down, sky_up, dir.y); //Get sky

*/