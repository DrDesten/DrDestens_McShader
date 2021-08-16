#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/framebuffer.glsl"

uniform sampler2D colortex4;

uniform float near;
uniform float nearInverse;
uniform float far;

uniform float frameTimeCounter;

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

in vec2 coord;

/* DRAWBUFFERS:0 */
void main() {
    vec3 color   = getAlbedo(coord);

    float blurAO = blurredAO(coord * 0.75, 0.5);
    //float blurAO = texture(colortex4, coord).x;
    color       *= blurAO;

    FD0 = vec4(vec3(color), (1.0));
}