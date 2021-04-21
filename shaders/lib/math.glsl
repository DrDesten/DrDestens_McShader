const float PI = 3.14159265358979323846;
const float PHI = 1.61803398874989484820459;

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

float pattern(vec2 seed, float size, float vW, float vH) {
    // Returns a gradient which repeats
    // the coords (akak seed) are multiplied by vW / vH in order to make square segments
    // Then they can be scaled to be bigger/smaller than one pixel.
    // The fractional component is extracted to repeat them between 0/1
    // x and y are averaged to create a linear gradient
    return (fract(seed.x * vW * size) + fract(seed.y * vH * size)) * 0.5;
}
float pattern_cross(vec2 seed, float size, float vW, float vH) {
    vec2 coord = floor(vec2(seed.x * vW / size, seed.y * vH / size)) * size;
    float modX = fract(coord.x * 0.5);
    float modY = fract(coord.y * 0.5);
    return float(modX == modY);
}
float pattern_cross2(vec2 seed, float size, float vW, float vH) {
    vec2 coord = floor(vec2(seed.x * vW / size, seed.y * vH / size)) * size;
    float modX1 = mod(coord.x, 3);
    float modY1 = mod(coord.y, 3);
    float modX2 = mod(coord.x + 1, 3);
    return (float(modX1 == modY1)) + (float(modX2 == modY1) * 0.5);
}
float pattern_cross_detail3(vec2 seed, float size, float vW, float vH) {
    vec2 coord = floor(vec2(seed.x * vW / size, seed.y * vH / size)) * size;
    float modX1 = mod(coord.x, 2);
    float modY1 = mod(coord.y, 2);
    float modX2 = mod(floor(coord.x * 0.6666666666) * 1.5, 2);
    float modY2 = mod(floor(coord.y * 0.6666666666) * 1.5, 2);
    float modX3 = mod(floor(coord.x * 0.3333333333) * 3,   2);
    float modY3 = mod(floor(coord.y * 0.3333333333) * 3,   2);
    return (float(modX1 == modY1) + (float(modX2 == modY2) * 0.75) + (float(modX3 == modY3) * 0.5)) * 0.444444444;
}
float pattern_cross_detail4(vec2 seed, float size, float vW, float vH) {
    vec2 coord = floor(vec2(seed.x * vW / size, seed.y * vH / size)) * size;
    float modX1 = fract(coord.x * 0.5);
    float modY1 = fract(coord.y * 0.5);
    float modX2 = fract(floor(coord.x * 0.3333333333) * 1.5);
    float modY2 = fract(floor(coord.y * 0.3333333333) * 1.5);
    float modX3 = fract(floor(coord.x * 0.2222222222) * 2.25);
    float modY3 = fract(floor(coord.y * 0.2222222222) * 2.25);
    return (float(modX1 == modY1) + (float(modX2 == modY2) * 0.75) + (float(modX3 == modY3) * 0.5)) * 0.444444444;
}

float rand(float n) { return fract(sin(n) * 43758.5453123); }

float randf_01(vec2 xy){
    xy = fract(xy);
    return fract(dot(xy, xy * PHI) * 324975.689);
}
float randf_11(vec2 xy){
    return randf_01(xy) * 2 -1;
}

float rand_01(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
float rand_11(vec2 co){
    return rand_01(co) * 2 - 1;
}


float hash(float n) { return fract(sin(n) * 1e4); }
float hash(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float noise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 x) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);
	// Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
	for (int i = 0; i < 2; ++i) {
		v += a * noise(x);
		x = rot * x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

float noise_f(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand_01(ip),rand_01(ip+vec2(1.0,0.0)),u.x),
		mix(rand_01(ip+vec2(0.0,1.0)),rand_01(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
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
