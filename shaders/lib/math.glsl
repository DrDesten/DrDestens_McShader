////////////////////////////////////////////////////////////////////////
// Constants

#define GAMMA 2.2

#define MAT2_ROT(angle, scale) \
    mat2(cos(angle) * scale, sin(angle) * scale, -sin(angle) * scale, cos(angle) * scale)

const float TWO_PI  = 6.2831853071795864769252867665590057683943387987502;
const float PI      = 3.1415926535897932384626433832795028841971693993751;
const float HALF_PI = 1.5707963267948966192313216916397514420985846996876;
const float INV_PI  = 0.3183098861837906715377675267450287240689192914809;

const float PHI     = 1.6180339887498948482045868343656381177203091798058;
const float PHI_INV = 0.6180339887498948482045868343656381177203091798058;
const float PHI2    = 1.32471795724474602596;

const float E       = 2.7182818284590452353602874713526624977572470937000;

const float SQRT2   = 1.4142135623730951;

////////////////////////////////////////////////////////////////////////
// General Functions

bool closeTo(float a, float b, float epsilon) {
    return abs(a-b) < epsilon;
}

float fstep(float edge, float x) { // Fast step() function with no branching
    return clamp((x - edge) * 1e36, 0, 1);
}
float fstep(float edge, float x, float slope) { // Fast step() function with no branching
    return clamp((x - edge) * slope, 0, 1);
}

float maxc(vec2 v) {
    return max(v.x, v.y);
}
float maxc(vec3 v) {
    return max(max(v.x, v.y), v.z);
}
float maxc(vec4 v) {
    return max(max(v.x, v.y), max(v.z, v.w));
}

float minc(vec2 v) {
    return min(v.x, v.y);
}
float minc(vec3 v) {
    return min(min(v.x, v.y), v.z);
}
float minc(vec4 v) {
    return min(min(v.x, v.y), min(v.z, v.w));
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

float mean(vec2 vector) {
    return (vector.x + vector.y) * 0.5;
}
float mean(vec3 vector) {
    return (vector.x + vector.y + vector.z) * 0.333333333333;
}
float mean(vec4 vector) {
    return ((vector.x + vector.y) + (vector.z + vector.w)) * 0.25;
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

float sqmag(vec2 v) {
    return dot(v, v);
}
float sqmag(vec3 v) {
    return dot(v, v);
}
float sqmag(vec4 v) {
    return dot(v, v);
}

float manhattan(vec2 v) {
    return abs(v.x) + abs(v.y);
}
float manhattan(vec3 v) {
    return abs(v.x) + abs(v.y) + abs(v.z);
}
float manhattan(vec4 v) {
    return (abs(v.x) + abs(v.y)) + (abs(v.z) + abs(v.w));
}

float manhattan(vec2 v1, vec2 v2) {
    return manhattan(v1-v2);
}
float manhattan(vec3 v1, vec3 v2) {
    return manhattan(v1-v2);
}
float manhattan(vec4 v1, vec4 v2) {
    return manhattan(v1-v2);
}

float sq(float x) { // Square
    return x * x;
}
vec2 sq(vec2 x) {
    return x * x;
}
vec3 sq(vec3 x) {
    return x * x;
}
vec4 sq(vec4 x) {
    return x * x;
}

float ssq(float x) { // Signed Square
    return x * abs(x);
}
vec2 ssq(vec2 x) {
    return x * abs(x);
}
vec3 ssq(vec3 x) {
    return x * abs(x);
}
vec4 ssq(vec4 x) {
    return x * abs(x);
}

float cb(float x) { // Cube
    return x * x * x;
}
vec2 cb(vec2 x) {
    return x * x * x;
}
vec3 cb(vec3 x) {
    return x * x * x;
}
vec4 cb(vec4 x) {
    return x * x * x;
}

float sqsq(float x) { // Cube
    return sq(sq(x));
}
vec2 sqsq(vec2 x) {
    return sq(sq(x));
}
vec3 sqsq(vec3 x) {
    return sq(sq(x));
}
vec4 sqsq(vec4 x) {
    return sq(sq(x));
}

float logn(float base, float res) { // Log base n
    return log2(res) / log2(base);
}

float saturate(float a) {
    return clamp(a, 0.0, 1.0);
}
vec2 saturate(vec2 a) {
    return clamp(a, 0.0, 1.0);
}
vec3 saturate(vec3 a) {
    return clamp(a, 0.0, 1.0);
}
vec4 saturate(vec4 a) {
    return clamp(a, 0.0, 1.0);
}

float angleBetween(vec3 v1, vec3 v2) {
    return acos(dot(normalize(v1), normalize(v2)));
}

float sqrtf01(float x) {
    return x * (2.0 - x);
}
vec2 sqrtf01(vec2 x) {
    return x * (2.0 - x);
}
vec3 sqrtf01(vec3 x) {
    return x * (2.0 - x);
}
vec4 sqrtf01(vec4 x) {
    return x * (2.0 - x);
}
float sqrtf13(float x) {
    return x * ( -0.23606797749978969641 * x + 1.23606797749978969641 );
}
vec2 sqrtf13(vec2 x) {
    return x * ( -0.23606797749978969641 * x + 1.23606797749978969641 );
}
vec3 sqrtf13(vec3 x) {
    return x * ( -0.23606797749978969641 * x + 1.23606797749978969641 );
}
vec4 sqrtf13(vec4 x) {
    return x * ( -0.23606797749978969641 * x + 1.23606797749978969641 );
}

float asinf(float x) { // s(x) = x + x³/8 + x^5/5
    float x2  = x*x;
    float x4  = x2*x2;
    return x + (x2 * x * .125) + (x4 * x * .2);
}
float acosf(float x) {
    return HALF_PI - asinf(x);
}

float smootherstep(float x) { // Second derivative zero as well
    return saturate( cb(x) * (x * (6. * x - 15.) + 10.) );
}
float smootherstep(float edge0, float edge1, float x) {
    x = saturate((x - edge0) * (1. / (edge1 - edge0)));
    return cb(x) * (x * (6. * x - 15.) + 10.);
}


float tri(float x) {
    return abs(fract(x) * 2 - 1);
}

////////////////////////////////////////////////////////////////////////
// Randomization and Dither Patterns

float Bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x * .5 + a.y * a.y * .75);
}
#define Bayer4(a)   (Bayer2 (0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer8(a)   (Bayer4 (0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer16(a)  (Bayer8 (0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer32(a)  (Bayer16(0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer64(a)  (Bayer32(0.5 * (a)) * 0.25 + Bayer2(a))

float ign(vec2 co) { // Interlieved Gradient Noise, very noice noise ( ͡° ͜ʖ ͡°)
    vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
    return fract( magic.z * fract( dot(co, magic.xy) ) );
}

float ditherColor(vec2 co) {
    return Bayer4(co) * (1./255) - (.5/255);
}

float checkerboard(vec2 co) {
    co = floor(co);
    return fract(co.x * 0.5 + co.y * 0.5);
}

vec2 R2(float n) {
    const vec2 a = vec2(1.0/PHI2, 1.0/(PHI2*PHI2));
    return fract(a * n + 0.5);
}

float rand(float x) {
    return fract(sin(x * 12.9898) * 4375.5453123);
}
float rand(vec2 x) {
    return fract(sin(x.x * 12.9898 + x.y * 78.233) * 4375.5453);
}

vec2 N22(vec2 x) {
    float t = rand(x);
    return vec2(t, rand(t * 50 - 25));
}
vec2 N12(float x) {
    float t = rand(x);
    return vec2(t, rand(t * 50 - 25));
}

float noise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
float noise(float x) {
    float i = floor(x);
    float f = fract(x);

	// Two connecting points
	float a = rand(i);
    float b = rand(i + 1.0);

	return smoothstep(a, b, f);
}

float fbm(vec2 x, int n) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);

	// Rotate to reduce axial bias
    const mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));

	for (int i = 0; i < n; ++i) {
		v += a * noise(x);
		x  = rot * x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

float fbm(vec2 x, int n, float scale, float falloff) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);

	// Rotate to reduce axial bias
    const mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));

	for (int i = 0; i < n; ++i) {
		v += a * noise(x);
		x  = rot * x * scale + shift;
		a *= falloff;
	}
	return v;
}

float voronoiSmooth(vec2 coord, float size, int complexity, float time) {
    vec2 uv  = coord;
    
    // Calculate Grid UVs (Also center at (0,0))
    vec2 guv = fract(uv * size) - .5;
    vec2 gid = floor(uv * size);

    float minDistance = 1e3;

    // Check neighboring Grid cells
    for (int x = -complexity; x <= complexity; x++) {
        for (int y = -complexity; y <= complexity; y++) {
        
            vec2 offset = vec2(x, y);
            
            // Get the id of current cell (pixel cell + offset by for loop)
            vec2 id    = gid + offset;
            // Get the uv difference to that cell (offset has to be subtracted)
            vec2 relUV = guv - offset;
            
            // Get Random Point (adjust to range (-.5, .5))
            vec2 p     = N22(id) - .5;
            p          = vec2(sin(time * p.x), cos(time * p.y)) * .5;
            
            // Calculate Distance bewtween point and relative UVs)
            vec2 tmp   = p - relUV;
            float d    = dot(tmp, tmp);
            
            // Select the smallest distance
            
            float h     = smoothstep( 0.0, 2.0, 0.5 + (minDistance-d) * 1.);
            minDistance = mix( minDistance, d, h ); // distance
            
        }
    }

    return minDistance;
}

float voronoi(vec2 coord, int search_radius) {
    vec2 uv  = coord;
    
    // Calculate Grid UVs (Also center at (0,0))
    vec2 guv = fract(uv) - .5;
    vec2 gid = floor(uv);

    float minDistance = 1e3;

    // Check neighboring Grid cells
    for (int x = -search_radius; x <= search_radius; x++) {
        for (int y = -search_radius; y <= search_radius; y++) {
        
            vec2 offset = vec2(x, y);
            
            // Get the id of current cell (pixel cell + offset by for loop)
            vec2 id    = gid + offset;
            // Get the uv difference to that cell (offset has to be subtracted)
            vec2 relUV = guv - offset;
            
            // Get Random Point (adjust to range (-.5, .5))
            vec2 p     = N22(id) - .5;
            
            // Calculate Distance bewtween point and relative UVs)
            vec2 tmp   = p - relUV;
            float d    = dot(tmp, tmp);
            
            // Select the smallest distance
            minDistance = min(d, minDistance);
            
        }
    }

    return minDistance;
}


////////////////////////////////////////////////////////////////////////
// Matrix Transformations

vec3 projectOrthographicMAD(in vec3 position, in mat4 projectionMatrix) {
    return vec3(projectionMatrix[0].x, projectionMatrix[1].y, projectionMatrix[2].z) * position + projectionMatrix[3].xyz;
}
vec2 projectOrthographicMAD(in vec2 position, in mat4x2 projectionMatrix) {
    return vec2(projectionMatrix[0].x, projectionMatrix[1].y) * position + projectionMatrix[3].xy;
}
vec3 projectPerspectiveMAD(in vec3 position, in mat4 projectionMatrix) {
    return projectOrthographicMAD(position, projectionMatrix) / -position.z;
}
vec2 projectPerspectiveMAD(in vec3 position, in mat4x2 projectionMatrix) {
    return projectOrthographicMAD(position.xy, projectionMatrix) / -position.z;
}
vec4 projectHomogeneousMAD(in vec3 position, in mat4 projectionMatrix) {
    return vec4(projectOrthographicMAD(position, projectionMatrix), -position.z);
}

vec3 unprojectOrthographicMAD(in vec2 position, in mat4 inverseProjectionMatrix) {
    return vec3(vec2(inverseProjectionMatrix[0].x, inverseProjectionMatrix[1].y) * position + inverseProjectionMatrix[3].xy, inverseProjectionMatrix[3].z);
}
vec3 unprojectPerspectiveMAD(in vec3 position, in mat4 inverseProjectionMatrix) {
    return unprojectOrthographicMAD(position.xy, inverseProjectionMatrix) / (inverseProjectionMatrix[2].w * position.z + inverseProjectionMatrix[3].w);
}
vec4 unprojectHomogeneousMAD(in vec3 position, in mat4 inverseProjectionMatrix) {
    return vec4(unprojectOrthographicMAD(position.xy, inverseProjectionMatrix), inverseProjectionMatrix[2].w * position.z + inverseProjectionMatrix[3].w);
}
vec3 transformMAD(in vec3 position, in mat4 transformationMatrix) {
    return mat3(transformationMatrix) * position + transformationMatrix[3].xyz;
}


////////////////////////////////////////////////////////////////////////
// Other Matrix Functions

mat3 rotationMatrix3DX(float angle) { // You can use mat2 instead, but flip angle and keep X. > vec3(x, mat2 * yz)
    float s = sin(angle);
    float c = cos(angle);
    return mat3(1, 0, 0,
                0, c,-s,
                0, s, c
           );
}
mat3 rotationMatrix3DZ(float angle) { // You can use mat2 instead, but flip angle and keep Z. > vec3(mat2 * xy, z)
    float s = sin(angle);
    float c = cos(angle);    
    return mat3(c, -s, 0,
                s,  c, 0,
                0,  0, 1
           );
}


mat3 rotationMatrix3D(vec3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c
           );
}

mat2 rotationMatrix2D(float angle) {
    float ca = cos(angle);
    float sa = sin(angle);
    return mat2(ca, sa, -sa, ca);
}

vec2 angleToVector(float angle) {
    return vec2(cos(angle), sin(angle));
}

vec3 arbitraryTangent(vec3 normal) {
    // Equivalent to: normalize( cross(normal, vec3(0,0,1)) )
    return vec3(normal.y, -normal.x, 0) * (1 / sqrt( sqmag( normal.xy ) ));
}

mat3 arbitraryTBN(vec3 normal) {
    // Equivalent to: cross(normal, vec3(0,0,1))
    vec3 tangent  = vec3(normal.y, -normal.x, 0);
    // Equivalent to: cross(normal, tangent)
    vec3 binomial = vec3(-normal.x * normal.z, normal.x * normal.z, (normal.y * normal.y) + (normal.x * normal.x));
    return mat3(normalize(tangent), normalize(binomial), normal);
}


////////////////////////////////////////////////////////////////////////
// Color-Specific functions

/* vec3 saturation(vec3 col, float saturation) {
    float brightness = dot(col, vec3(0.299, 0.587, 0.112));
    return mix(vec3(brightness), col, saturation);
}

vec3 contrast(vec3 col, float contrast) {
    vec3 lower = (contrast * col) * (col * col);
    vec3 upper = 1 - contrast * sq(col - 1);
    return mix(lower, upper, col);
} */

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}
float saturation(vec3 color, float luma) {
    return distance(vec3(luma), color);
}
float saturation(vec3 color) {
    return saturation(color, luminance(color));
}


vec3 applyBrightness(vec3 color, float brightness, float colorOffset) { // Range: inf-0
	float tmp = (1 / (2 * colorOffset + 1));
	color = color * tmp + (colorOffset * tmp);
	return pow(color, vec3(brightness));
}
vec3 applyContrast(vec3 color, float contrast) { // Range: 0-inf
	color = color * 0.99 + 0.005;
	vec3 colorHigh = 1 - 0.5 * pow(-2 * color + 2, vec3(contrast));
	vec3 colorLow  =     0.5 * pow( 2 * color,     vec3(contrast));
	return saturate(mix(colorLow, colorHigh, color));
}
vec3 applySaturation(vec3 color, float saturation) { // Range: 0-2
    return saturate(mix(vec3(luminance(color)), color, saturation));
}
vec3 applyVibrance(vec3 color, float vibrance) { // -1 to 1
	float luminance  = luminance(color);
	float saturation = distance(vec3(luminance), color);
	return applySaturation(color, (1 - saturation) * vibrance + 1);
}

vec3 rgb2hsv(vec3 c) {
    const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
    const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 gamma(vec3 color) {
    color = pow(color, vec3(GAMMA));
    return color;
}
vec3 gamma_inv(vec3 color) {
    color = pow(color, vec3(1 / GAMMA));
    return color;
}

vec3 normalizeColor(vec3 col) {
    col += 1e-5; // prevent NaNs
    return col / max(col.r, max(col.g, col.b));
}

vec4 cubic(float v) {
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

vec4 textureBicubic(sampler2D sampler, vec2 coord, vec2 samplerSize, vec2 pixelSize) {
    coord = coord * samplerSize - 0.5;

    vec2 fxy = fract(coord);
    coord -= fxy;

    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);

    vec4 c = coord.xxyy + vec2 (-0.5, +1.5).xyxy;

    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;

    offset *= pixelSize.xxyy;

    vec4 sample0 = texture(sampler, offset.xz);
    vec4 sample1 = texture(sampler, offset.yz);
    vec4 sample2 = texture(sampler, offset.xw);
    vec4 sample3 = texture(sampler, offset.yw);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix(
        mix(sample3, sample2, sx), 
        mix(sample1, sample0, sx)
    , sy);
}

float triangle(float x) {
    return saturate(1 - abs(x));
}
float sincNorm(float x) {
    return x == 0 ? 1 : sin(x*PI) / (x*PI);
}
float bell(float x) {
    return exp(-(x*x*2));
}

vec4 textureSmoothstep(sampler2D sampler, vec2 coord, vec2 samplerSize, vec2 samplerSizeInverse) {
    vec2 icoord    = coord * samplerSize;
    vec2 pixCoord  = fract(icoord);
    //pixCoord       = pixCoord * (pixCoord * (4 * pixCoord - 6) + 3);
    pixCoord       = pixCoord * (pixCoord * (2.22222 * pixCoord - 3.33333) + 2.11111);
    return texture(sampler, (floor(icoord) + pixCoord) * samplerSizeInverse);
}


/////////////////////////////////////////////////////////////////////////////////////////
//                                 TONEMAPPING

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
vec3 reinhard_sqrt_tonemap_inverse(vec3 color, float a) {
    return sqrt(a) * color * inversesqrt(-color * color + 1);
}


vec3 unreal_tonemap(vec3 color) {
  return color / (color + 0.155) * 1.019;
}


vec3 exp_tonemap(vec3 color, float a) {
    return 1 - exp(-color * a);
}


/////////////////////////////////////////////////////////////////////////////////
//                              OTHER FUNCTIONS

float peak05(float x) { return x * (-4*x + 4); }
vec2  peak05(vec2 x)  { return x * (-4*x + 4); }
vec3  peak05(vec3 x)  { return x * (-4*x + 4); }
vec4  peak05(vec4 x)  { return x * (-4*x + 4); }

float lineDist2P(vec2 coord, vec2 start, vec2 end) {
    vec2 pa = coord - start;
    vec2 ba = end - start;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0, 1);
    return sqmag(ba * -t + pa);
}
float line2P(vec2 coord, vec2 start, vec2 end, float thickness) {
    return fstep(lineDist2P(coord, start, end), thickness * thickness);
}
float line2P(vec2 coord, vec2 start, vec2 end, float thickness, float slope) {
    thickness = thickness * thickness;
    return saturate((thickness - lineDist2P(coord, start, end)) * slope + 1);
}

float lineDist1P1V(vec2 coord, vec2 start, vec2 dir) {
    vec2 pa = coord - start;
    float t = dot(pa, dir) / dot(dir, dir);
    return sqmag(dir * -t + pa);
}
float line1P1V(vec2 coord, vec2 start, vec2 dir, float thickness) {
    return fstep(lineDist1P1V(coord, start, dir), thickness * thickness);
}
float line1P1V(vec2 coord, vec2 start, vec2 dir, float thickness, float slope) {
    thickness = thickness * thickness;
    return saturate((thickness - lineDist1P1V(coord, start, dir)) * slope + 1);
}

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}
float mapclamp(float value, float from_min, float from_max, float to_min, float to_max) {
    return clamp(map(from_min, from_max, to_min, to_max, value), to_min, to_max);
}

vec2 convertPolarCartesian(vec2 coord) {
    return vec2(coord.x * cos(coord.y), coord.x * sin(coord.y));
}

float linearizeDepth(float d,float nearPlane,float farPlane) { // Linearizes the depth to viewspace z
    d = 2.0 * d - 1.0; // Convert to NDC (normalized device coordinates)
    return 2.0 * nearPlane * farPlane / (farPlane + nearPlane - d * (farPlane - nearPlane));
}
float linearizeDepthInverse(float l, float nearPlane, float farPlane) { // Un-Linearizes viewspace z to screenspace depth
    return (farPlane * (l-nearPlane))/(l * (farPlane-nearPlane));
}
float linearizeDepthf(float d, float slope) { // For matching results, slope should be set to 1/nearPlane
    return 1 / ((-d * slope) + slope);
}
float linearizeDepthfDivisor(float d, float slope) { // Returns 1 / linearizeDepthf For matching results, slope should be set to 1/nearPlane
    return (-d * slope) + slope;
}
float linearizeDepthfInverse(float ld, float slope) { // For matching results, slope should be set to 1/nearPlane
    return 1 / (-ld * slope) + 1;
}

float schlickFresnel(vec3 viewRay, vec3 normal, float refractiveIndex, float baseReflectiveness) {
    //Schlick-Approximation of Fresnel
    float R0 = (1 - refractiveIndex) / (1 + refractiveIndex);
    R0 *= R0;

    float cosAngle = dot(viewRay, normal);
    float reflectiveness = R0 + ( (1 - R0) * pow(1 - cosAngle, 5) );
    reflectiveness = clamp(1 - reflectiveness, 0, 1) + baseReflectiveness;
    return reflectiveness;
}
float schlickFresnel(vec3 viewDir, vec3 normal, float F0) {
    float NormalDotView = clamp(dot(-viewDir, normal), 0, 1);
    return F0 + (1.0 - F0) * pow(1.0 - NormalDotView, 5.0);
}
float customFresnel(vec3 viewRay, vec3 normal, float bias, float scale, float power) {
    float reflectiveness = clamp(bias + scale * pow(1.0 + dot(viewRay, normal), power), 0, 1); 
    return reflectiveness;
}

// Spins A point around the origin (negate for full coverage)
vec2 spiralOffset(float x, float expansion) {
    float n = fract(x * expansion) * PI;
    return vec2(cos(n), sin(n)) * x;
}
vec2 spiralOffset_full(float x, float expansion) {
    float n = fract(x * expansion) * TWO_PI;
    return vec2(cos(n), sin(n)) * x;
}


vec2 radClamp(vec2 coord) {
    // Center at 0,0
    coord = coord - 0.5;
    // Calculate oversize vector by subtracting 1 on each axis from the absulute
    // We just need the length so sing doesnt matter
    vec2 oversize = max(vec2(0), abs(coord) - 0.5);
    coord        /= (length(oversize) + 1);
    coord         = coord + 0.5;
    return coord;
}
vec3 radClamp(vec3 coord) {
    // Center at 0,0
    coord = coord - 0.5;
    // Calculate oversize vector by subtracting 1 on each axis from the absulute
    // We just need the length so sign doesnt matter
    vec3 oversize = max(vec3(0), abs(coord) - 0.5);
    coord /= (length(oversize) + 1);
    coord = coord + 0.5;
    return coord;
}
vec2 mirrorClamp(vec2 coord) { //Repeats coords while mirroring them (without branching)

    // Determines whether an axis has to be flipped or not
    vec2 reversal = mod(floor(coord), vec2(2));
    vec2 add      = reversal;
    vec2 mult     = reversal * -2 + 1;

    coord         = fract(coord);
    // Flips the axis
    // Flip:    1 - coord = -1 * coord + 1
    // No Flip:     coord =  1 * coord + 0
    // Using these expressions I can make the flipping branchless
    coord         = mult * coord + add;

    return coord;
}
vec2 distortClamp(vec2 coord) {
    coord = coord * 2 - 1;

    vec2 d = abs(coord * 1.5);
    d      = max(d-1.5, 0);
    coord *= exp2(-d);
 
    return coord * .5 + .5;
}


float smoothCutoff(float x, float cutoff, float taper) {
    if (x > cutoff + taper) {return x;}
    float a   = cutoff / (taper*taper*taper);
    float tmp = (x - cutoff - taper);
    return clamp( (a * tmp) * (tmp * tmp) + x ,0,1);
}

float angle(vec2 v) {
    float ang = HALF_PI - atan(v.x / v.y);
    if(v.y < 0) {ang = ang + PI;}
    return ang;
}


////////////////////////////////////////////////////////////////////////
// (Un)Packing Functions

vec2 signNotZero(vec2 v) {
    return vec2((v.x >= 0.0) ? +1.0 : -1.0, (v.y >= 0.0) ? +1.0 : -1.0);
}

vec2 octahedralEncode(in vec3 v) {
    float l1norm = abs(v.x) + abs(v.y) + abs(v.z);
    vec2  result = v.xy * (1.0 / l1norm);
    if (v.z < 0.0) {
        result = (1.0 - abs(result.yx)) * signNotZero(result.xy);
    }
    return result;
}

vec3 octahedralDecode(vec2 o) {
    vec3 v = vec3(o.x, o.y, 1.0 - abs(o.x) - abs(o.y));
    if (v.z < 0.0) {
        v.xy = (1.0 - abs(v.yx)) * signNotZero(v.xy);
    }
    return normalize(v);
}


vec3 Int24ToVec3_asfloat(float x) {
    int ix = int(x * 16777216.);
    return vec3(
        ix & 255,          // Bitwise AND. Masks the first 8 bits (255 -> 11111111 in binary, AND operation zeros out all other bits)
        (ix >> 8)  & 255,  // Bitshift down by 8. Moves the first 8 bits out. Afterwards, selecting the first 8 bits again (this isolates bit 9-16)
        (ix >> 16) & 255   // Same principle
    ) * (1./255);
}
vec3 Int24ToVec3(int x) {
    return vec3(
        x & 255,          // Bitwise AND. Masks the first 8 bits (255 -> 11111111 in binary, AND operation zeros out all other bits)
        (x >> 8)  & 255,  // Bitshift down by 8. Moves the first 8 bits out. Afterwards, selecting the first 8 bits again (this isolates bit 9-16)
        (x >> 16) & 255   // Same principle
    ) * (1./255);
}


vec2 Int16ToVec2_asfloat(float x) {
    int ix = int(x * 65536.);
    return vec2(
        ix & 255,        // Bitwise AND. Masks the first 8 bits (255 -> 11111111 in binary, AND operation zeros out all other bits)
        (ix >> 8) & 255  // Bitshift down by 8. Moves the first 8 bits out. Afterwards, selecting the first 8 bits again (this isolates bit 9-16)
    ) * (1./255);
}
vec2 Int16ToVec2(int x) {
    return vec2(
        x & 255,         // Bitwise AND. Masks the first 8 bits (255 -> 11111111 in binary, AND operation zeros out all other bits)
        (x >> 8) & 255   // Bitshift down by 8. Moves the first 8 bits out. Afterwards, selecting the first 8 bits again (this isolates bit 9-16)
    ) * (1./255);
}



int Vec3ToInt24(vec3 x) {
    ivec3 ix = ivec3(x * 255.);
    return ix.x + (ix.y << 8) + (ix.z << 16);
}
float Vec3ToInt24_asfloat(vec3 x) {
    ivec3 ix = ivec3(x * 255.);
    return float( ix.x + (ix.y << 8) + (ix.z << 16) ) * (1./16777216.);
}

int Vec2ToInt16(vec2 x) {
    ivec2 ix = ivec2(x * 255.);
    return ix.x + (ix.y << 8);
}
float Vec2ToInt16_asfloat(vec2 x) {
    ivec2 ix = ivec2(x * 255.);
    return float( ix.x + (ix.y << 8) ) * (1./65536.);
}