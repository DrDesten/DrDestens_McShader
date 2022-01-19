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
    #ifdef TAA
        float sharpen_amount = clamp(length(cameraPosition - previousCameraPosition) * 1e2, 0.6, 2.5 * MC_RENDER_QUALITY) * (TAA_SHARPENING_AMOUNT);
        vec3  color = saturate(sharpen(coord, sharpen_amount, 0.07));
    #else
        vec3  color = getAlbedo(coord);
        //color = smartUpscale(colortex0, coord).rgb;
    #endif

    //color = mix(color, color * color * vec3(1,.5,.5), isHurtSmooth * 0.5);

    // Remove Banding (yay)
    const float displayPrecision = 1./255.;
    color                       += (Bayer4(coord * screenSize) - .5) * displayPrecision;

    gl_FragColor = vec4(color, 1.0);
}

