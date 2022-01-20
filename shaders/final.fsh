#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

#ifdef TAA
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
#endif

void main() {
    vec3  color = getAlbedo(coord);
    color = gamma_inv(color);

    color = color / sqrt(0.5 + color);

    // Remove Banding (yay)
    const float displayPrecision = 1./255.;
    color                       += (Bayer4(coord * screenSize) - .5) * displayPrecision;

    gl_FragColor = vec4(color, 1.0);
}

