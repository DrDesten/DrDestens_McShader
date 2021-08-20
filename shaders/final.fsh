#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"
#include "/lib/kernels.glsl"

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform int frameCounter;

in vec2 coord;

/* 
    float normalAwareBlur(vec2 coord, float size, float stepsize) {
        vec3 normal = getNormal(coord);
        float AO    = 0;

        float samples = 0;

        for( float x = -size; x <= size; x++ ) {
            for( float y = -size; y <= size; y++ ) {

                vec2 samplePos    = vec2(x, y) * stepsize * screenSizeInverse + coord;
                vec3 sampleNormal = getNormal(samplePos);

                float blend       = clamp(dot(normal, sampleNormal), 0, 1);

                AO               += texture(colortex4, samplePos).x * blend;
                samples          += blend;
            
            }
        }

        return AO / samples;
    }

    float normalDepthAwareBlur(vec2 coord, float size, float stepsize) {
        vec3 normal = getNormal(coord);
        float depth = linearizeDepthf(getDepth(coord), 1/near);
        float AO    = 0;

        float samples = 0;

        for( float x = -size; x <= size; x++ ) {
            for( float y = -size; y <= size; y++ ) {

                vec2 samplePos    = vec2(x, y) * stepsize * screenSizeInverse + coord;
                vec3 sampleNormal = getNormal(samplePos);
                float sampleDepth = linearizeDepthf(getDepth_int(samplePos), 1/near);

                float blend       = clamp(dot(normal, sampleNormal), 0, 1) * clamp(1 - abs(depth - sampleDepth), 0, 1);

                AO               += texture(colortex4, samplePos).x * blend;
                samples          += blend;
            
            }
        }

        return AO / samples;
    }

    float blurredAO(vec2 coord, float scale) {
        vec3  normal = getNormal(coord);
        float depth  = linearizeDepthf(getDepth(coord), nearInverse);
        float AO     = 1;

        float samples = 1;

        for( int x = -1; x <= 1; x+=2 ) {
            for( int y = -1; y <= 1; y+=2 ) {

                vec2 samplePos    = vec2(x, y) * scale * screenSizeInverse + coord;
                vec3 sampleNormal = getNormal(samplePos);
                float sampleDepth = linearizeDepthf(getDepth_int(samplePos), nearInverse);

                float blend       = clamp(dot(normal, sampleNormal), 0, 1) * clamp(1 - abs(depth - sampleDepth), 0, 1);

                AO               += texture(colortex4, samplePos).x * blend;
                samples          += blend;
            
            }
        }

        return AO / samples;
    }

*/

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

void main() {
    vec3 color = getAlbedo(coord);
    
    #ifdef TAA
        float sharpen_amount = clamp(length(cameraPosition - previousCameraPosition) * 50, 1., 1.5);
        color = sharpen(coord, sharpen_amount, 0.05);
    #endif

    // Remove Banding (yay)
    float displayPrecision = 1./255.;
    color                 += vec3((Bayer4(coord * screenSize) - .5) * displayPrecision);

    gl_FragColor = vec4(color, 1.0);
}

