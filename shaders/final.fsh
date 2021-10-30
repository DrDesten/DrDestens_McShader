

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/kernels.glsl"

#ifdef TAA
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
#endif

in vec2 coord;

vec3 gaussian_3x3(vec2 coord) {
    vec2 e = vec2(-.5, .5);
    vec3 color  = texture(colortex0, screenSizeInverse * e.yy + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.xx + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.yx + coord).rgb;
         color += texture(colortex0, screenSizeInverse * e.xy + coord).rgb;
    return color * 0.25;
}

vec3 sharpen(vec2 coord, float amount, float maximum) {
    vec3 blurred  = gaussian_3x3(coord);
    vec3 color    = getAlbedo(coord);

    return clamp((color - blurred) * amount, -maximum, maximum) + color;
}

float cDist(vec4 col1, vec4 col2) {
    return abs(sum(col1.rgb) - sum(col2.rgb));
}

vec4 smartUpscale(sampler2D tex, vec2 coord) {
    vec2 texSize = vec2(textureSize(tex, 0));
    vec2 pixel   = 1. / texSize;
    
    vec2 rCoord  = floor(coord * texSize + .5) * pixel;
    
    vec4 color   = texture(tex, coord);
    vec4 lastCol = vec4(1e10);
    for (float x = -0.5; x < 0.6; x += 1.) {
        for (float y = -0.5; y < 0.6; y += 1.) {
            vec2 offs = vec2(x,y) * pixel;
            vec4 sCol = texture(tex, rCoord + offs);
            
            if (cDist(color, lastCol) > cDist(color, sCol)) {
                lastCol = sCol;
            }
        }
    }
    
    return lastCol;
}

void main() {
    #ifdef TAA
        float sharpen_amount = clamp(length(cameraPosition - previousCameraPosition) * 50, 1., 1.5);
        vec3  color = saturate(sharpen(coord, sharpen_amount, 0.05));
        //vec3  color = texture(colortex5, coord).rgb;
    #else
        vec3  color = getAlbedo(coord);
        //color = smartUpscale(colortex0, coord).rgb;
    #endif

    // Remove Banding (yay)
    const float displayPrecision = 1./255.;
    color                       += (Bayer4(coord * screenSize) - .5) * displayPrecision;

    //color = vec3(pow(getDepth(coord), 50));

    gl_FragColor = vec4(color, 1.0);
}

