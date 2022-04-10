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
uniform vec3  sunPosition;
uniform vec3  moonPosition;
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

    normal = normalize(vec3(noiseRight - v, dx, noiseDown - v));
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
        float moonBrightness = 1./16;
        vec3  cloudNormal;

        // CLOUD SHAPE AND GENERATION //////////////////////////////////////////////////////////////////////////////

        // Necessary Positions for Cloud Calculations
        vec3 viewPos      = toView(screenPos * 2 - 1);
        vec3 viewDir      = normalize(viewPos);
        vec3 playerEyePos = toPlayerEye(viewPos);
        vec3 playerEyeDir = normalize(playerEyePos);

        // Normalized Light Positions
        vec3 sunDir  = normalize(sunPosition);
        vec3 moonDir = normalize(moonPosition);

        // Get Coordinates for clouds
        vec2 cloudCoord = normalize(playerEyePos * vec3(1,CLOUD_COORD_DISTORT,1)).xz;
        cloudCoord      = cloudCoord * CLOUD_COORD_DISTORT + (frameTimeCounter * 0.03);

        // Sample Noise and get Cloud Surface Normals
        float cloudHeight = fbmCloud(cloudCoord, 6, 3.75, 0.3, cloudNormal);
        cloudHeight       = saturate(cloudHeight * 1.75 - 0.75) * 5;

        // Blend factor that determines the blending factor between clouds and sky
        float isCloud = 1 - exp(-cloudHeight);
        isCloud      *= saturate(playerEyeDir.y * 3); // Cloud horizon


        // CLOUD LIGHTING ////////////////////////////////////////////////////////////////////////////////////////

        #define LIGHT_TRANSITION_PERIOD 0.1
        float cloudBrightness = 0;
        float sunContribution  = saturate(((0.5 + LIGHT_TRANSITION_PERIOD) - daynight) * (1./LIGHT_TRANSITION_PERIOD));
        float moonContribution = saturate((daynight - (0.5 - LIGHT_TRANSITION_PERIOD)) * (1./LIGHT_TRANSITION_PERIOD));


        if (sunContribution > 0) {
            float sunDotView = dot(sunDir, viewDir);

            float volumeAlongRay     = sq(cloudHeight) * (abs(sunDotView) * (2 - HALF_PI) + HALF_PI); // How thick is the cloud along the view ray in direction to the light source
            float visibilityAlongRay = exp(-volumeAlongRay);
            float anisotropicScatter = KleinNishina(sunDotView, 100) * visibilityAlongRay * 10;
            float diffuseCloud       = dot(toPlayerEye(sunDir), cloudNormal) * -0.5 + 0.5;

            cloudBrightness += (anisotropicScatter + diffuseCloud) * sunBrightness * sunContribution;
        }
        if (moonContribution > 0) {
            float moonDotView = dot(moonDir, viewDir);

            float volumeAlongRay     = sq(cloudHeight) * (abs(moonDotView) * (2 - HALF_PI) + HALF_PI); // How thick is the cloud along the view ray in direction to the light source
            float visibilityAlongRay = exp(-volumeAlongRay);
            float anisotropicScatter = KleinNishina(moonDotView, 100) * visibilityAlongRay * 10;
            float diffuseCloud       = dot(toPlayerEye(moonDir), cloudNormal) * -0.5 + 0.5;

            cloudBrightness += (anisotropicScatter + diffuseCloud) * moonBrightness * moonContribution;
        }

        #ifdef OVERWORLD
        // Sun and Moon disappear under the horizon
        color *= saturate(playerEyeDir.y * 1.5 + 0.3);
        #endif

        vec3 skyColor = getSky(playerEyePos);
        color = mix(color * (1-isCloud) + skyColor, vec3(cloudBrightness), isCloud);

        //color = vec3(cloudNormal.xy * 0.5 + 0.5, 0);


    } else { // NO SKY


    }
    
    gl_FragData[0] = vec4(color, 1.0);
}