#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform float rainStrength;
#include "/lib/sky.glsl"

uniform vec3  lightPosition;
uniform float frameTimeCounter;

//////////////////////////////////////////////////////////////////////////////
//                     SKY RENDERING
//////////////////////////////////////////////////////////////////////////////

float rayleighPhase(float cosTheta) {
    return 3./4. * (cosTheta * cosTheta + 1);
}
float KleinNishina(float cosTheta, float e) {
    // For clouds, e has to be around 700-1000
    return e / (2.0 * PI * (e * (1.0 - cosTheta) + 1.0) * log(2.0 * e + 1.0));
}

float fbmCloud(vec2 x, int n, float scale, float falloff) {
	float v = 0.0;
	float a = 1.0 - (1. / scale);
	vec2 shift = vec2(50);

	// Rotate to reduce axial bias
    const mat2 rot = mat2(cos(PHI_INV*0.5), sin(PHI_INV*0.5), -sin(PHI_INV*0.5), cos(PHI_INV*0.5));

	for (int i = 0; i < n; ++i) {
		v += a * noise(x);
		x  = rot * x * scale + shift;
		a *= falloff;
	}
	return v;
}
float fbmCloud(vec2 x, int n, float scale, float falloff, out vec3 normal) {
	float v = 0.0;
	float a = 1.0 - (1. / scale);
	vec2 shift = vec2(50);

	// Rotate to reduce axial bias
    const mat2 rot = mat2(cos(PHI_INV), sin(PHI_INV), -sin(PHI_INV), cos(PHI_INV));

    const float dx = 0.5;
    float noiseRight  = noise(x + vec2(dx, 0));
    float noiseDown   = noise(x + vec2(0, dx));

	for (int i = 0; i < n; ++i) {
		v += a * noise(x);
		x  = rot * x * scale + shift;
		a *= falloff;
	}

    normal = normalize(vec3(noiseRight - v, noiseDown - v, dx));
	return v;
}

/* DRAWBUFFERS:0 */
void main() {
    float depth     = getDepth(coord);
    vec3  screenPos = vec3(coord, depth);
    vec3  color     = getAlbedo(coord);
    
    if (depth >= 1) { // SKY

        #define CLOUD_COORD_DISTORT 7
        float sunBrightness = 1;
        vec3  cloudNormal;

        vec3 viewPos      = toView(screenPos * 2 - 1);
        vec3 viewDir      = normalize(viewPos);
        vec3 playerEyePos = toPlayerEye(viewPos);
        vec3 skyColor     = getSky(playerEyePos);

        vec3  playerEyeDirDistort = normalize(playerEyePos * vec3(1,CLOUD_COORD_DISTORT,1));
        vec2  cloudCoord  = playerEyeDirDistort.xz * CLOUD_COORD_DISTORT + (frameTimeCounter * 0.03);
        float cloudHeight = fbmCloud(cloudCoord, 6, 3.75, 0.3, cloudNormal);
        cloudHeight       = saturate(cloudHeight * 1.75 - 0.75) * 5;

        float isCloud = 1 - exp(-cloudHeight);
        isCloud      *= saturate(playerEyeDirDistort.y * (10/CLOUD_COORD_DISTORT)); // Cloud horizon

        float sunDotView = dot(normalize(lightPosition), viewDir);

        float volumeAlongRay     = sq(cloudHeight) * (abs(sunDotView) * (2 - HALF_PI) + HALF_PI); // How thick is the cloud along the view ray in direction to the light source
        float visibilityAlongRay = exp(-volumeAlongRay);
        float anisotropicScatter = KleinNishina(sunDotView, 100) * visibilityAlongRay * 10;
        float diffuseCloud       = dot(normalize(toPlayerEye(lightPosition) * vec3(1,CLOUD_COORD_DISTORT,1)), cloudNormal) * -0.5 + 0.5;

        vec3 cloudColor = vec3(anisotropicScatter + diffuseCloud) * sunBrightness;

        #ifdef OVERWORLD
        // Sun and Moon disappear under the horizon
        color *= saturate(playerEyeDirDistort.y * (10/CLOUD_COORD_DISTORT) + 0.75);
        #endif

        color = mix(color * (1-isCloud) + skyColor, cloudColor, isCloud);

        //color = vec3(cloudNormal.xy * 0.5 + 0.5, 0);

    } else { // NO SKY


    }
    
    gl_FragData[0] = vec4(color, 1.0);
}