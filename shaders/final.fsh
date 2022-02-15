#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse * MC_RENDER_QUALITY;

#ifdef TAA
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
#endif

//uniform float isHurtSmooth;

vec3 gaussian_3x3(vec2 coord) {
    vec2 e = vec2(-.5, .5) / MC_RENDER_QUALITY;
    vec3 color  = texture(colortex0, screenSizeInverse * e.yy + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.xx + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.yx + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.xy + coord).rgb;
    return color * 0.25;
}
vec3 sharpen(vec2 coord, float amount, float maximum) {
    vec3 blurred  = gaussian_3x3(coord);
    vec3 color    = getAlbedo_int(coord);

    return clamp((color - blurred) * amount, -maximum, maximum * .33333) + color;
    //return clamp((color - blurred) * amount, -maximum, maximum) + color;
}
vec3 sharpen2(vec2 coord, float amount, float maximum) {
    vec2 e = vec2(-.5, .5) / MC_RENDER_QUALITY;
    vec3 c  = texture(colortex0, coord).rgb;
    vec3 nw = texture(colortex0, screenSizeInverse * e.xy + coord).rgb;
    vec3 ne = texture(colortex0, screenSizeInverse * e.yy + coord).rgb;
    vec3 sw = texture(colortex0, screenSizeInverse * e.xx + coord).rgb;
    vec3 se = texture(colortex0, screenSizeInverse * e.yx + coord).rgb;

    float maxVal = max(max(nw.g, ne.g), max(sw.g, se.g));
    float minVal = min(min(nw.g, ne.g), min(sw.g, se.g));

    float sharpenAmount = amount * (min(1.0-maxVal, minVal) / maxVal);

    vec3 colorDiff = c - (nw + ne + sw + se) * 0.25;

    return colorDiff * sharpenAmount + c;
}


float lanczosWeight(float x, float r) {
    return x == 0.0 ? 1. : (r * sin(PI * x) * sin(PI * (x / r) )) / ( (PI*PI) * sq(x));
}
float lanczosWeight(vec2 x, float r) {
    return lanczosWeight(x.x, r) * lanczosWeight(x.y, r);
}

vec3 lanczos(vec2 coord, int r) {
    vec2 res    = screenSize;
    vec2 ccoord = floor(coord * res) / res;
    vec2 icoord = floor(coord * res);

    vec3  total  = vec3(0);    
    for (int x = -r; x <= r; x++) {
        for (int y = -r; y <= r; y++) {
            vec2  offs = vec2(x,y);
            
            vec2  sampleCoords = icoord + offs;
            vec3  val          = texelFetch(colortex0, ivec2(sampleCoords), 0).rgb;
            
            vec2  d            = sampleCoords - (coord * res);
            float weight = lanczosWeight(d, float(r));
            
            total     += val * weight;
        }
    }

    return total;
}

void main() {
    #ifdef TAA
        float sharpen_amount = clamp(length(cameraPosition - previousCameraPosition) * 1e2, 1.5, 3.5 * MC_RENDER_QUALITY) * (TAA_SHARPENING_AMOUNT);
        vec3  color = saturate(sharpen2(coord, sharpen_amount, 2));
    #else
        vec3  color = getAlbedo_int(coord);
    #endif

    // Remove Banding (yay)
    const float displayPrecision = 1./255.;
    color                       += (Bayer4(coord * screenSize) - .5) * displayPrecision;

    //color = vec3(coord, 0);

    gl_FragColor = vec4(color, 1.0);
}

