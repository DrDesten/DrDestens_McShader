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
uniform float cloudCoverageSmooth;

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
		v += a * valueNoise(x);
		x  = rot * x * scale + shift;
		a *= falloff;
	}
	return v;
}
float fbmCloud(vec2 x, out vec3 normal) {
	float v = 0.0;
	float a = 1.0;
	vec2 shift = vec2(50);

	// Rotate to reduce axial bias
    const mat2 rots = mat2(cos(PHI_INV), sin(PHI_INV), -sin(PHI_INV), cos(PHI_INV)) * CLOUD_NOISE_OCTAVE_SCALE;

    const float dx = 0.25;
    float noiseRight  = valueNoise(x + vec2(dx, 0));
    float noiseDown   = valueNoise(x + vec2(0, dx));

	for (int i = 0; i < CLOUD_NOISE_DETAIL; ++i) {
		v += a * valueNoise(x);
		x  = shift + rots * x;
		a *= CLOUD_NOISE_FALLOFF;
	}
    
    const float exponent = 1./CLOUD_NOISE_FALLOFF;
    const float factor  = (exponent-1) / (exponent - pow(exponent, 1-CLOUD_NOISE_DETAIL));

    normal = normalize(vec3(noiseRight - v, dx, noiseDown - v));
	return v * factor;
}

/* DRAWBUFFERS:0 */
void main() {
    float depth     = getDepth(coord);
    vec3  screenPos = vec3(coord, depth);
    vec3  color     = getAlbedo(coord);
    
    if (depth >= 1) { // SKY

        #ifdef OVERWORLD

        float sunBrightness  = 2;
        float moonBrightness = 1./50;
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
        vec3 cloudSpace = normalize(playerEyePos * vec3(1,CLOUD_COORD_DISTORT + (cameraPosition.y * (10./CLOUD_HEIGHT)),1));
        vec2 cloudCoord = cloudSpace.xz;
        cloudCoord      = cloudCoord * (CLOUD_SCALE * CLOUD_COORD_DISTORT) + (frameTimeCounter * (0.02 * CLOUD_SPEED));
        cloudCoord      = cameraPosition.xz * (1./(CLOUD_HEIGHT)) + cloudCoord;

        // Sample Noise and get Cloud Surface Normals
        float cloudHeight = fbmCloud(cloudCoord, cloudNormal);
        cloudHeight       = saturate(
            mix( cloudHeight * (1./CLOUD_COVERAGE) - ((1./CLOUD_COVERAGE)-1),
                 cloudHeight, cloudCoverageSmooth )
        );
        cloudHeight      *= CLOUD_THICKNESS;

        // Blend factor that determines the blending factor between clouds and sky
        float isCloud = 1 - exp(-cloudHeight);
        isCloud      *= saturate(playerEyeDir.y * 3); // Cloud horizon


        // CLOUD LIGHTING ////////////////////////////////////////////////////////////////////////////////////////

        float cloudBrightness = 0;
        vec3  ambientColor    = mix(vec3(1), sqrt(sunset_color), sunset) * (rainStrength * -0.75 + 1);
        float sunContribution  = saturate(((0.5 + CLOUD_LIGHT_TRANSITION_PERIOD) - daynight) * (.5/CLOUD_LIGHT_TRANSITION_PERIOD));
        float moonContribution = saturate((daynight - (0.5 - CLOUD_LIGHT_TRANSITION_PERIOD)) * (.5/CLOUD_LIGHT_TRANSITION_PERIOD));

        vec3  sunDirPlayerEye    = toPlayerEye(sunDir);
        float sunDotView         = dot(sunDir, viewDir);
        float volumeAlongRay     = sq(cloudHeight) * (abs(sunDotView) * (2 - HALF_PI) + HALF_PI); // How thick is the cloud along the view ray in direction to the light source
        float visibilityAlongRay = exp(-volumeAlongRay * CLOUD_DENSITY);
        float visibility         = exp(-cloudHeight * CLOUD_DENSITY);
        float diffuseCloud       = dot(sunDirPlayerEye, cloudNormal);

        if (sunContribution > 0) {

            float anisotropicScatter = KleinNishina(sunDotView, 800) * visibilityAlongRay;
            float interpolator       = smootherstep(-diffuseCloud);
            float densityMixFactor   = visibility * (1 - interpolator) + interpolator;
            cloudBrightness         += (
                (diffuseCloud * -0.5 + 0.5) * densityMixFactor +
                anisotropicScatter
            ) * sunBrightness * sunContribution;

        }
        if (moonContribution > 0) {

            float anisotropicScatter = KleinNishina(-sunDotView, 800) * visibilityAlongRay;
            float interpolator       = smootherstep(diffuseCloud);
            float densityMixFactor   = visibility * (1 - interpolator) + interpolator;
            cloudBrightness         += (
                (diffuseCloud * 0.5 + 0.5) * densityMixFactor +
                anisotropicScatter
            ) * moonBrightness * moonContribution;

        }

        // Sun and Moon (and Stars) disappear under the horizon
        color *= saturate(playerEyeDir.y * 1.5 + 0.2);

        vec3 skyColor = getSky(saturate(playerEyeDir.y));
        color = mix(color * sq(1-isCloud) + skyColor, cloudBrightness * ambientColor, isCloud);

        #else

        color += getSky(toPlayerEye(toView(screenPos * 2 - 1)));

        #endif

    } else { // NO SKY


    }
    
    gl_FragData[0] = vec4(color, 1.0);
}