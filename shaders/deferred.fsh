#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/transform.glsl"
#include "/lib/composite/basics.glsl"
#include "/lib/composite/color.glsl"
#include "/lib/composite/depth.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
#include "/lib/sky.glsl"

//////////////////////////////////////////////////////////////////////////////
//                     SKY RENDERING
//////////////////////////////////////////////////////////////////////////////

/* DRAWBUFFERS:0 */
void main() {
    float depth     = getDepth(coord);
    vec3  screenPos = vec3(coord, depth);
    vec3  color     = getAlbedo(coord);
    
    if (depth >= 1) { // SKY

        #ifdef OVERWORLD
            color += getSky(toPlayerEye(toView(screenPos * 2 - 1)));
        #else
            color = getSky(toPlayerEye(toView(screenPos * 2 - 1)));
        #endif

    } else { // NO SKY


    }
    
    gl_FragData[0] = vec4(color, 1.0);
}