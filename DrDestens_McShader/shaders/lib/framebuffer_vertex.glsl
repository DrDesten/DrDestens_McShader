
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

const float PI = 3.14159265358979323846;
const float PHI = 1.61803398874989484820459;

/* Long code
vec4 vertPos  = gl_Vertex;
vec4 viewPos  = gl_ModelViewMatrix * vertPos;
vec4 playerPos = gbufferModelViewInverse * viewPos; 
*/
vec4 vertexPlayer() {
    return gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
}

vec4 vertexWorldToClip(vec4 vertex) {
    return gl_ProjectionMatrix * (gbufferModelView * vertex);
}


////////////////////////////////////////////////////////////////////////
// Randomization and Dither Patterns

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

float noise(vec2 p, float freq){
	float unit = 1/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = randf_01((ij+vec2(0.,0.)));
	float b = randf_01((ij+vec2(1.,0.)));
	float c = randf_01((ij+vec2(0.,1.)));
	float d = randf_01((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
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

float noise_ff(vec2 p, float size) {
    //p = floor(p * size) / size;
    
    float fac1 = randf_01(floor(p * size) / size);
    float fac2 = randf_01(floor(p * size * 5) / (size * 5));
    //float fac3 = randf_01(floor(p * size * 25) / (size * 25));
    
    //return (fac1 + fac2 + fac3) * 0.33333333333;
    return (fac1 + fac2) * 0.5;
}

////////////////////////////////////////////////////////////////////////
// Vector-specific functions

mat3 rotateAxisAngle(vec3 u, float angleRadians) {
    float sinA = sin( angleRadians );
    float cosA = cos( angleRadians );
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

